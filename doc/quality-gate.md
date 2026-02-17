# Quality Gate (Cursor Hook)

Bramka jakości uruchamiana przed ryzykownymi operacjami (commit, push, PR, publikacja paczek). Blokuje wykonanie, jeśli szybkie checki (lint/test) nie przejdą.

## Jak działa

- **Hook:** `beforeShellExecution` wywołuje `python3 hooks/before_shell_quality_gate.py`.
- Skrypt czyta komendę z JSON na stdin. Jeśli komenda **nie** jest „gated” → zwraca `permission: allow`.
- Komendy gated: `git commit`, `git push`, `gh pr create`, `gh pr merge`, `npm publish`, `pnpm publish`, `yarn publish` (wykrywane w całym stringu, także w `cd ... && git commit ...`).
- Dla komend gated:
  1. Obliczany jest klucz cache (HEAD + `git diff --name-only`).
  2. Jeśli ten sam klucz jest w `hooks/.quality_gate_state.json` i ostatni wynik to PASS → allow (bez ponownego uruchamiania checków).
  3. W przeciwnym razie uruchamiany jest quality gate (patrz niżej); wynik zapisywany w `hooks/.quality_gate_state.json`.
  4. PASS → allow, FAIL → deny z komunikatami dla użytkownika i agenta.

Hook **stop** wywołuje `python3 hooks/stop_quality_gate_followup.py`. Jeśli ostatni gate = FAIL, zwraca `followup_message` z przypomnieniem (uruchom `scripts/quality-gate.py`, napraw błędy).

## Konfiguracja

- **hooks.json** (w głównym katalogu repo): wpisy `beforeShellExecution` i `stop` jak w `doc/hooks.md`.
- Skrypty: `hooks/before_shell_quality_gate.py`, `hooks/stop_quality_gate_followup.py`.
- Stan: `hooks/.quality_gate_state.json` (w `.gitignore`).

## Checki jakości (cross-platform: Windows + WSL)

1. **scripts/quality-gate.py** — Python 3, działa na Windows i WSL. Hook uruchamia go jako `python scripts/quality-gate.py <repo_root>`.
2. Gdy nie ma tego skryptu → hook wykrywa stack po plikach:
   - **package.json** → `npm run lint` / `npm run format` / `npm run test` (pierwszy znaleziony);
   - **pyproject.toml** → `ruff check .`, `pytest -q --tb=no -x`;
   - **Makefile** → `make lint` / `make test` / `make check` / `make format`.
3. Jeśli repo nie ma żadnych z tych plików/checków → gate zwraca PASS („No repo checks configured”).

**Dodanie / zmiana checków:** edytuj `scripts/quality-gate.py` (funkcja `run_checks()`). Skrypt ma być szybki; w CI możesz wywołać ten sam plik.

## Debugowanie

- **Cursor → Output → Hooks:** logi z hooków (stdout/stderr skryptów).
- Ręczne testowanie skryptu:
  ```bash
  echo '{"command":"git commit -m test","workspace_roots":["'$(pwd)'"]}' | python3 hooks/before_shell_quality_gate.py
  ```
- Stan cache: `cat hooks/.quality_gate_state.json`. Aby wymusić ponowne uruchomienie gate, usuń ten plik lub zmień zawartość (np. commit).
- Na Windows: jeśli `python3` nie jest w PATH, w `hooks.json` użyj `python` zamiast `python3`.

## Testowanie

**Skrypt testowy (WSL lub środowisko z Pythonem):**
```bash
python3 scripts/test-quality-gate-hook.py
```
Sprawdza: (1) komenda niegated → allow, (2) komenda gated → uruchomienie gate i allow/deny, (3) hook stop.

**Ręcznie:**
1. **Bez blokady:** `git status`, `ls` → hook zwraca allow.
2. **Z blokadą:** wprowadź celowy błąd (np. zły format w pliku, który łapie linter), potem `git commit -m "test"`. Oczekiwane: deny + komunikat „Quality gate FAIL”.
3. Napraw błędy, uruchom `scripts/quality-gate.py` (lub odpowiednie checki repo), ponów commit → allow.

Na Windows bez Pythona w PATH użyj WSL: `wsl -e bash -c "cd /mnt/c/Users/janja/.cursor && python3 scripts/test-quality-gate-hook.py"`.
