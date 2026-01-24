# Cursor Deeplinks – instrukcja projektowa (ChatGPT + Cursor)

Ten dokument opisuje, jak w tym projekcie **generować i używać Cursor Deeplinks** (prompt/command/rule oraz MCP install linki),
w szczególności jako **operacyjne instrukcje generowane przez ChatGPT** i uruchamiane w Cursorze.

Źródło prawdy: oficjalna dokumentacja Cursor:
- Deeplinks: https://cursor.com/docs/integrations/deeplinks.md
- MCP Install Links: https://cursor.com/docs/context/mcp/install-links.md

---

## 1) Kontrakty URL (oficjalna specyfikacja)

Cursor obsługuje dwa równoważne formaty deeplinków:

**App link (bezpośrednio do aplikacji Cursor):**
- `cursor://anysphere.cursor-deeplink/<path>?<params>`

**Web link (pośrednio przez cursor.com):**
- `https://cursor.com/link/<path>?<params>`

W projektowej dokumentacji i w ChatGPT preferujemy **web link** jako „primary” (jest częściej klikalny),
ale zawsze generujemy też **app link** jako „secondary”.

### 1.1 Prompt deeplink

Path: `/prompt`  
Parametry: `text=<promptText>`

- Web: `https://cursor.com/link/prompt?text=...`
- App: `cursor://anysphere.cursor-deeplink/prompt?text=...`

### 1.2 Command deeplink

Path: `/command`  
Parametry: `name=<commandName>`, `text=<commandContent>`

- Web: `https://cursor.com/link/command?name=...&text=...`
- App: `cursor://anysphere.cursor-deeplink/command?name=...&text=...`

Cursor utworzy plik polecenia w `.cursor/commands` po zatwierdzeniu przez użytkownika.

### 1.3 Rule deeplink

Path: `/rule`  
Parametry: `name=<ruleName>`, `text=<ruleContent>`

- Web: `https://cursor.com/link/rule?name=...&text=...`
- App: `cursor://anysphere.cursor-deeplink/rule?name=...&text=...`

Cursor utworzy regułę w `.cursor/rules` po zatwierdzeniu przez użytkownika.

### 1.4 Maksymalna długość

Deeplink URL ma limit **8,000 znaków** (po URL-encoding).  
Jeśli przekraczasz limit: skróć treść (lub wygeneruj artefakt w repo inną metodą, np. przez agenta w Cursorze).

---

## 2) MCP Install Links (MCP serwery jako deeplinki)

Format:

```text
cursor://anysphere.cursor-deeplink/mcp/install?name=$NAME&config=$BASE64_ENCODED_CONFIG
```

- `name` – nazwa serwera
- `config` – base64(JSON.stringify(transportConfig))

W praktyce:
1. Masz nazwę serwera, np. `postgres`
2. Masz transport config (jak w `mcp.json`) np. `{"command":"npx","args":[...]}`
3. Stringify -> base64 -> wstaw do query param `config`

---

## 3) Zasady bezpieczeństwa i UX

- Deeplinki **nigdy nie wykonują się automatycznie**. Użytkownik zawsze przegląda i zatwierdza treść w Cursorze.
- Przed udostępnieniem deeplinka sprawdź, czy nie zawiera sekretów (API keys, hasła, prywatne fragmenty kodu).

---

## 4) Standard odpowiedzi ChatGPT w tym projekcie (Output Contract)

Gdy prosisz ChatGPT o deeplink, ChatGPT musi zwrócić:

1. **WEB link (primary)**  
2. **APP link (secondary)**  
3. **Expected result** (co się stanie po zatwierdzeniu w Cursorze, np. gdzie powstanie plik)  
4. Krótka notatka: „sprawdź sekrety + limit 8k”

---

## 5) Jak używać w praktyce (workflow)

1. Opisz ChatGPT *co chcesz osiągnąć*: prompt / command / rule / MCP server install
2. ChatGPT generuje 2 linki + expected result
3. Klikasz web link (lub wklejasz app link w przeglądarce)
4. Cursor pokaże podgląd treści → zatwierdzasz
5. Commitujesz zmiany w repo (jeśli dotyczy plików `.cursor/...`)

---

## 6) Generator w repo (zalecane)

W repo trzymaj generator deeplinków:

- `scripts/cursor-deeplink-gen.py`

Pozwala:
- uniknąć błędów URL-encoding
- automatycznie policzyć długość URL (limit 8,000)
- generować linki także dla MCP install

### 6.1 Instalacja / użycie

```bash
python3 scripts/cursor-deeplink-gen.py prompt --text "Create a README for this repo" --md
python3 scripts/cursor-deeplink-gen.py command --name "run-all-tests" --text "Run the full test suite and fix failures" --md
python3 scripts/cursor-deeplink-gen.py rule --name "python-style" --text "Prefer ruff/black; avoid implicit Any." --md
python3 scripts/cursor-deeplink-gen.py mcp-install --name postgres --config-file mcp.json --md
```

---

## 7) Gotowy prompt do ChatGPT (do wklejenia w PROJECT_RULES.md)

```md
### Cursor Deeplinks (standard projektu)

Gdy proszę o deeplink, zwróć:
1) WEB link (https://cursor.com/link/...)
2) APP link (cursor://anysphere.cursor-deeplink/...)
3) Expected result (jakie pliki/punkty konfiguracji powstaną po zatwierdzeniu w Cursorze)
4) Notatkę: „Sprawdź sekrety + limit 8,000 znaków URL”

Wspierane formaty:
- prompt: /prompt?text=...
- command: /command?name=...&text=...
- rule: /rule?name=...&text=...
- MCP install: /mcp/install?name=...&config=... (config = base64(JSON.stringify(transportConfig)))
```

---
