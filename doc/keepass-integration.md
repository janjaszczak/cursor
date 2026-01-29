# KeePassXC Integration — Runbook

This runbook describes how to set up KeePassXC integration with Cursor so that secrets (passwords, API tokens, SSH keys) are available to the agent and scripts without storing them in repo files. Use it to **reproduce the setup on a new machine** (Windows, WSL, Linux, or macOS).

## 1. Introduction

**Why:** Secure handling of secrets for Cursor and MCP: no `.env` files with passwords in the repo; one master password in a keyring, all other secrets in a KeePassXC database.

**Architecture (short):**

- **Keyring** (PowerShell SecretManagement / secret-tool / macOS Keychain) = **only** the KeePassXC database password.
- **KeePassXC database** (`.kdbx` file) = **all** secrets (passwords, tokens, keys).
- **keepassxc-cli** + helper scripts (bash or Python) = read and write entries; scripts get the DB password from the keyring.

## 2. Prerequisites

- **KeePassXC** installed (GUI + CLI). Install from [KeePassXC](https://keepassxc.org/). Ensure `keepassxc-cli` is on your PATH (e.g. `keepassxc-cli --version`).
- **For bash scripts:** bash; on Windows/WSL, PowerShell for SecretManagement.
- **For Python scripts (optional):** Python 3; `scripts/keepass_ops.py` if you use the Python helper.
- **Keyring:** One of:
  - **Windows / WSL:** PowerShell SecretManagement + SecretStore (recommended).
  - **WSL / Linux:** `secret-tool` (requires D-Bus).
  - **macOS:** Keychain (if supported by the scripts you use).

## 3. Step-by-Step — New Machine

### 3.1 Create the database (if you don’t have one)

1. Open KeePassXC GUI.
2. **File → New Database.** Save as e.g. `cursor.kdbx` in a known location (e.g. OneDrive/Dropbox for sync, or a local path).
3. Set a **strong master password** (and optionally a key file). Remember this password; it will be stored in the keyring once in step 3.4.

### 3.2 Database path and KEEPASS_DB_PATH

Set the environment variable to the full path of your `cursor.kdbx`:

| OS | Example path |
|----|----------------|
| Windows | `C:\Users\<user>\OneDrive\Dokumenty\Inne\cursor.kdbx` |
| WSL | `/mnt/c/Users/<user>/OneDrive/Dokumenty/Inne/cursor.kdbx` |
| Linux | `~/.config/cursor/cursor.kdbx` or `~/cursor.kdbx` |
| macOS | `~/.config/cursor/cursor.kdbx` or `~/cursor.kdbx` |

- **WSL / Linux:** Add to `~/.profile` and/or `~/.bashrc`:
  ```bash
  export KEEPASS_DB_PATH="/path/to/cursor.kdbx"
  ```
- **Windows:** Set in PowerShell profile or System Properties → Environment Variables:
  ```powershell
  $env:KEEPASS_DB_PATH = "C:\Users\<user>\...\cursor.kdbx"
  ```
  For a permanent user variable, use `[Environment]::SetEnvironmentVariable("KEEPASS_DB_PATH", "C:\...", "User")`.

### 3.3 Entry “Cursor Database Password” in the database

So that the keyring can be filled without typing the DB password manually later:

1. In KeePassXC, create an entry with **Title** = `Cursor Database Password` (or the name your script expects).
2. Set the entry’s **Password** field to the **same** master password as the database.
3. Save the database. This entry is used only by `save-keepass-password-to-keyring` when the DB is open in the GUI to copy the password into the keyring.

### 3.4 Keyring — first-time setup (per OS)

**Windows / WSL (PowerShell SecretManagement):**

1. Install modules (if missing):
   ```powershell
   Install-Module -Name Microsoft.PowerShell.SecretManagement -Scope CurrentUser
   Install-Module -Name Microsoft.PowerShell.SecretStore -Scope CurrentUser
   ```
2. Register the vault (once):
   ```powershell
   Register-SecretVault -Name LocalStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
   ```
3. Open `cursor.kdbx` in KeePassXC GUI. Run:
   ```bash
   ~/.cursor/scripts/save-keepass-password-to-keyring.sh
   ```
   The script reads the password from the “Cursor Database Password” entry and stores it in LocalStore under a fixed name (e.g. `KeePassXC-Cursor-DB`). After this, CLI/scripts can unlock the DB without the GUI.

**WSL / Linux (secret-tool):**

1. Ensure D-Bus is available and `secret-tool` is installed.
2. With the DB open in KeePassXC GUI, run the same script; it will store the DB password with `secret-tool store` (e.g. `service=keepassxc`, `attribute=cursor-db`).

**macOS:**  
If your scripts support macOS Keychain, follow the script’s documentation; otherwise use SecretManagement via PowerShell if installed.

### 3.5 Clone or copy the .cursor repo

Ensure the following are present (e.g. by cloning your cursor-config repo into `~/.cursor` or copying files):

- `scripts/get-keepass-secret.sh`
- `scripts/save-keepass-password-to-keyring.sh`
- Optionally: `scripts/keepass_ops.py` (if you use the Python helper)
- `skills/keepass-integration/` (for the agent)

On WSL/Windows, ensure scripts are executable: `chmod +x ~/.cursor/scripts/*.sh`.

### 3.6 Verification

1. **KEEPASS_DB_PATH:**  
   ```bash
   echo $KEEPASS_DB_PATH   # WSL/Linux/macOS
   ```
   Or in PowerShell: `echo $env:KEEPASS_DB_PATH`. Should print the path to `cursor.kdbx`.

2. **Keyring:**  
   Close KeePassXC GUI. Run:
   ```bash
   ~/.cursor/scripts/get-keepass-secret.sh "Cursor Database Password" "Password"
   ```
   It should print the database password without prompting. If it prompts, keyring setup failed — repeat 3.4.

3. **CLI:**  
   ```bash
   keepassxc-cli ls "$KEEPASS_DB_PATH"
   ```
   Should list groups/entries (may ask for password if keyring not used; with keyring it should not).

## 4. Data structure in the database (for agent and scripts)

Use a consistent hierarchy so that scripts and the agent can “check before add” and avoid duplicates:

- **Groups:** `{project_name}/{env_name}` (e.g. `myapp/prod`, `myapp/dev`).
- **Entries:** Inside a group, use **Title** for the secret name (e.g. “GitHub Token”, “API Key”) and **Password** (or a custom attribute) for the secret value.

This allows:

- `keepassxc-cli ls "$KEEPASS_DB_PATH" "ProjectName/EnvName"` to see existing entries.
- `keepassxc-cli locate` to find an entry before add/update.
- Add only when the entry does not exist; otherwise use **edit** (see skill and scripts).

## 5. Scripts — what lives where

| Script | Purpose | When to use |
|--------|---------|-------------|
| `get-keepass-secret.sh` | Read one attribute (e.g. Password) of an entry by title/path | From Cursor, terminal, or other scripts. Example: `get-keepass-secret.sh "MyApp/prod/API Key" "Password"` |
| `save-keepass-password-to-keyring.sh` | Store the DB password into the keyring (from the “Cursor Database Password” entry) | Once per machine after opening the DB in GUI; repeat if keyring was cleared. |
| `keepass_ops.py` | Python helper: get / add / update with check-before-add | When you prefer Python or need add/update from the CLI. Example: `python3 keepass_ops.py get "ProjectName/EnvName/EntryTitle" --attr Password` |

Paths are relative to `~/.cursor/` (e.g. `~/.cursor/scripts/get-keepass-secret.sh`).

## 6. SSH Agent (KeePassXC)

KeePassXC can load SSH keys from the database into the system SSH agent when the DB is unlocked in the GUI.

- **Enable:** KeePassXC → **Tools → Settings → SSH Agent** → enable.
- **Requirement:** A running ssh-agent (Windows: OpenSSH Authentication Agent or Pageant; WSL/Linux: usually already running).
- **Verify:** After opening the DB in KeePassXC, run `ssh-add -l`; your keys should appear.

See [KeePassXC User Guide — SSH Agent](https://keepassxc.org/docs/KeePassXC_UserGuide.html).

## 7. Database sync (optional)

To sync `cursor.kdbx` with another database (e.g. main personal DB):

- **KeeShare** (recommended): GUI-based sync in KeePassXC.
- **Merge:** One-time merge from another file.

Details depend on your workflow; see configuration or your integration plan.

## 8. Troubleshooting

| Problem | What to check |
|--------|----------------|
| “Cannot read database password” | Is the DB open in KeePassXC? Does the entry “Cursor Database Password” exist and contain the DB master password? Run `save-keepass-password-to-keyring.sh` again. |
| `keepassxc-cli: command not found` | Install KeePassXC (apt/snap/brew/winget) and ensure CLI is on PATH. |
| “Cannot retrieve secret from SecretManagement” | PowerShell: Are SecretManagement and SecretStore installed? Is LocalStore registered? Try `Get-Secret -Name KeePassXC-Cursor-DB -Vault LocalStore -AsPlainText`. |
| SSH keys not in `ssh-add -l` | KeePassXC → Settings → SSH Agent enabled? Is ssh-agent running (e.g. `Start-Service ssh-agent` on Windows)? |

## 9. References

- **Current setup summary:** [configuration.md](configuration.md) (KeePassXC Integration subsection)
- **Agent skill (workflow, add/update, check-before-add):** [skills/keepass-integration/SKILL.md](../skills/keepass-integration/SKILL.md)
- **KeePassXC User Guide:** [KeePassXC User Guide](https://keepassxc.org/docs/KeePassXC_UserGuide.html)
- **KeePassXC CLI:** [keepassxreboot/keepassxc](https://github.com/keepassxreboot/keepassxc)
