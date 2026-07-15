# Analiza: Ponytail i Impeccable — wdrożenie w Cursorze

**Punkt wyjścia:** prośba o analizę dwóch trendujących projektów AI-agent-skill/plugin
(GitHub, lipiec 2026) i decyzję jak je wdrożyć w tym repo (`~/.cursor` — single source
of truth dla Cursor: `USER_RULES.txt`, `AGENTS.default.md`, `agents/`, `commands/`,
`skills/`, `hooks.json`).

---

## 1. Co to za projekty

### 1.1 [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)

„Makes your AI agent think like the laziest senior dev in the room." Plugin/skill dla
agentów kodujących wymuszający minimalizm przed napisaniem kodu — **drabinka
leniwości**, sprawdzana zanim agent zacznie pisać:

1. Czy to musi istnieć? → nie: pomiń (YAGNI)
2. Już jest w repo? → użyj ponownie, nie pisz od nowa
3. Stdlib to robi? → użyj stdlib
4. Natywna funkcja platformy? → użyj jej
5. Zainstalowana zależność to robi? → użyj jej
6. Jedna linia wystarczy? → jedna linia
7. Dopiero teraz: minimum kodu, które działa

**Nigdy nie na liście do wycięcia:** walidacja granic zaufania, obsługa utraty danych,
bezpieczeństwo, dostępność (a11y). Zmierzony efekt (agentowy benchmark na FastAPI+React):
średnio **-54% linii kodu**, -22% tokenów, -20% kosztu, -27% czasu, przy 100% "safe"
(żadnej z pominiętych kategorii bezpieczeństwa).

Dystrybucja: plugin dla Claude Code/Codex/Copilot CLI/OpenCode/Gemini CLI/Devin/Pi/
Hermes/Qoder/OpenClaw (hooki + slash-commands `/ponytail`, `/ponytail-review`,
`/ponytail-audit`, `/ponytail-debt`, `/ponytail-gain`, `/ponytail-help`). Dla **Cursor**
projekt jawnie deklaruje status **„instruction-only"**: brak natywnego runtime'u dla
pluginów/hooków tego typu — rekomendacja autora to skopiowanie statycznego pliku reguł
z `.cursor/rules/` do projektu (bez komend, bez trybów `lite/full/ultra`).

### 1.2 [pbakaus/impeccable](https://github.com/pbakaus/impeccable)

„The design language that makes your AI harness better at design." Skill do projektowania
UI dla agentów kodujących (rozwinięcie Anthropicowego `frontend-design`). Adresuje
rozpoznawalne „AI slop" w designie: font Inter wszędzie, gradienty fioletowo-niebieskie,
karty w kartach, szary tekst na kolorowym tle, zaokrąglony kwadratowy icon-tile nad każdym
nagłówkiem, easing bounce/elastic.

Zawiera:
- **1 skill, 23 komendy** (`/impeccable init|craft|shape|critique|audit|polish|distill|
  harden|bolder|quieter|colorize|typeset|layout|animate|onboard|delight|overdrive|
  clarify|adapt|optimize|live|document|extract`)
- **46 deterministycznych reguł detektora** (bez LLM, bez API key) + LLM-only critique
- CLI (`npx impeccable install|update|detect|link|ignores`) + hook natywny per-host

Dla **Cursor** projekt ma pełne wsparcie (nie tylko „instruction-only"):
`npx impeccable install` wykrywa `.cursor/`, instaluje skill + **`.cursor/hooks.json`**
z hookiem, który **blokuje złe zapisy zanim wejdą** (inne hosty tylko zgłaszają problem
po edycji). Wymaga: kanał **Nightly** (Settings → Beta) + **Agent Skills** włączone
(Settings → Rules) — zgodnie z `skills/vanilla-web/SKILL.md` w tym repo, które już
zakłada `Cursor Agent Skills (Nightly)`.

---

## 2. Ograniczenia Cursora vs. natywne dystrybucje obu projektów

| Mechanizm w ponytail/impeccable | Cursor dziś |
|---|---|
| Plugin marketplace + `/plugin install` | Nie istnieje w Cursor |
| Lifecycle hooks (`UserPromptSubmit`, `PreToolUse` na subagentach) | Cursor ma **własny** `hooks.json` (inny format: `preToolUse`/`beforeShellExecution`/`beforeMCPExecution`/`stop`) — patrz [`doc/hooks.md`](hooks.md) |
| Slash-commands z pluginu (`/ponytail-review`, `/impeccable audit`) | Cursor ma własne **Custom Commands** (`.cursor/commands/*.md`) — inny mechanizm, trzeba odtworzyć |
| Agent Skills (Claude/Codex od dawna) | Cursor: **tylko Nightly + flag** (`Settings → Rules → Agent Skills`), potwierdzone już w `skills/vanilla-web` i `skills/impeccable-design` (nowy) w tym repo |
| Zawsze aktywny ruleset wstrzykiwany co turę | Cursor: **User Rules** (`USER_RULES.txt`) — to jest odpowiednik |

Wniosek: żadnego z dwóch projektów nie da się „zainstalować" w Cursorze 1:1 jak w
Claude Code. Trzeba przełożyć ich mechanikę na istniejące prymitywy tego repo
(User Rules / AGENTS.default.md / skills/ / commands/ / hooks.json), a nie kopiować
pliki `dist/cursor/.cursor` bez przemyślenia — to nadpisałoby konwencje już ustalone
w `doc/rules.md` i `skills/README.md`.

---

## 3. Opcje wdrożenia

### 3.1 Ponytail

**Opcja A — statyczny plik reguł per-projekt** (rekomendacja autora ponytail dla
"instruction-only" hostów: skopiować `.cursor/rules/ponytail.mdc` do każdego projektu).
- Plusy: 1:1 z upstream, łatwe do zaktualizowania (`git pull` w checkout ponytail).
- Minusy: **niezgodne z architekturą tego repo** — `doc/rules.md` mówi wprost, że
  `.cursor/rules/*.mdc` w projekcie jest tylko dla reguł **stack-specific** (globs), a
  globalne, zawsze-aktywne zasady żyją w `USER_RULES.txt` per user, nie per projekt.
  Trzeba by kopiować plik do każdego repo ręcznie — dokładnie problem, który
  `AGENTS.default.md` + User Rules już rozwiązały dla `AGENTS.md`.

**Opcja B — wpleść drabinkę do `USER_RULES.txt` (STATIC PRINCIPLES)** ✅ wybrana.
- Ponytail jest z definicji „always on" (wstrzykiwany co turę) — to jest semantycznie
  to samo co `USER_RULES.txt` w tym repo (per user, wszystkie projekty, zawsze
  aktywne). Jedna zwięzła linia w STATIC PRINCIPLES (już zawiera SOLID/DRY/KISS/YAGNI)
  jest właściwym miejscem, nie nowy plik na projekt.
- Plusy: zero setupu per-projekt, konsekwentne z resztą pliku (zwięzłość — ROLE mówi
  „Concise by default"), nie wymaga Nightly/Agent Skills.
- Minusy: nie replikuje trybów `lite/full/ultra/off` — uznane za YAGNI (ten repo nie ma
  koncepcji „intensywności" w innych zasadach; jeśli okaże się potrzebne, można dodać
  krótką notatkę o override w `AGENTS.default.md`, ale nie na starcie).

**Opcja C — pełny skill + command na audyt/review** ✅ wybrana (uzupełnia B).
- `/ponytail-review`, `/ponytail-audit`, `/ponytail-debt` z upstream to **komendy
  on-demand**, nie „always on" — naturalnie mapują się na istniejący wzorzec
  `commands/*.md` (jak `/cleanup`, `/retro`) + skill `skills/ponytail/SKILL.md` z pełną
  procedurą audytu, zamiast plugin-runtime.
- Odrzucono osobne repo/checkout ponytail jako zależność — cały mechanizm (drabinka +
  lista „nigdy nie wycinaj") mieści się w ~50 liniach, więc wektoring jako natywny
  skill jest prostszy niż zarządzanie submodułem dla czystej logiki tekstowej.

### 3.2 Impeccable

**Opcja A — zwektoryzować cały `dist/cursor/.cursor` do tego repo (globalnie)**.
- Odrzucona: Impeccable jest **domenowy** (frontend/UI), nie każdy projekt tego
  potrzebuje (por. `python-backend`, `data-import-parsers` — repo świadomie trzyma
  skille per-domena, wybierane kontekstowo, nie każdy zawsze aktywny). Globalny hook
  blokujący zapisy plików UI byłby szkodliwy w projektach bez frontendu.
- Dodatkowo `.impeccable/` generuje stan runtime (screenshoty, cache sesji live-mode) —
  to per-projekt working state, nie coś do trzymania w `~/.cursor`.

**Opcja B — git submodule per projekt** (opcja z upstream README).
- Właściwa dla **konkretnego projektu frontendowego**, nie dla tego repo (config
  repo nie ma własnego UI do projektować).

**Opcja C — skill-checklista globalna + instrukcja instalacji CLI per-projekt na żądanie** ✅ wybrana.
- Nowy `skills/impeccable-design/SKILL.md` (Domain tier, jak `vanilla-web`/`next-stack`):
  skondensowana checklista 46 reguł + kiedy zaproponować `npx impeccable install` w
  **konkretnym** projekcie (nie w tym repo). Zgodne z GUARDRAILS („MCP outputs
  untrusted; confirm before external writes") — instalacja CLI to zapis + sieć, więc
  wymaga potwierdzenia użytkownika, nigdy automatyczna.
- Plusy: dostępne w każdym projekcie od razu (jak inne Domain-skille), zero
  network/write ryzyka w tym repo, pełna instalacja CLI zostaje decyzją per-projekt.
- Minusy: bez CLI nie ma live-mode w przeglądarce i 46 deterministycznych reguł
  (0 false-negatives) — tylko LLM-based checklist. Zaakceptowane: to review-time
  guardrail, nie zamiennik pełnego narzędzia.

---

## 4. Rekomendacja i podsumowanie działań

| Działanie | Priorytet | Uwagi |
|---|---|---|
| Wpleść drabinkę ponytail do `USER_RULES.txt` → STATIC PRINCIPLES | Wysoki | Always-on, per user, zero setupu |
| Skill **`skills/ponytail/SKILL.md`** (Domain tier) | Wysoki | Audyt/review on-demand, źródło: DietrichGebert/ponytail |
| Komenda **`commands/ponytail_review.md`** (`/ponytail_review`) | Wysoki | Zamiennik `/ponytail-review`/`/ponytail-audit`/`/ponytail-debt` |
| Skill **`skills/impeccable-design/SKILL.md`** (Domain tier) | Średni | Checklista + kiedy sugerować `npx impeccable install` per projekt |
| **Nie** wektoryzować `dist/cursor/.cursor` z impeccable do tego repo | — | Domenowe, per-projekt; runtime state (`.impeccable/`) nie należy do config repo |
| **Nie** kopiować statycznego `.cursor/rules/ponytail.mdc` per projekt | — | Zastąpione przez USER_RULES.txt (per user, nie per repo) |
| Zaktualizować `doc/commands.md`, `USER_RULES.txt` (wersja 3.6.0 → 3.7.0) | Wysoki | Katalog skilli + nowa komenda |

### Co pozostaje decyzją per-projekt (nie w tym repo)
- Faktyczny `npx impeccable install` (sieć, zapisuje `.cursor/hooks.json` i
  `.cursor/skills/impeccable/` w **projekcie**, nie w `~/.cursor`) — agent proponuje to
  tylko gdy projekt robi trwałą pracę frontendową i użytkownik potwierdza.
- Włączenie kanału Nightly + Agent Skills w Cursor Settings — wymagane dla
  `impeccable-design` (i już wymagane dla `vanilla-web`), poza zakresem tego repo
  (ustawienie IDE, nie plik w repo).

---

## 5. Weryfikacja

- `skills/ponytail/SKILL.md` i `skills/impeccable-design/SKILL.md` mają frontmatter
  zgodny z resztą `skills/*/SKILL.md` (`name`, `description`, `compatibility`,
  `metadata.author/version`) — spójne z `skills/solid`, `skills/vanilla-web`.
- `commands/ponytail_review.md` ma strukturę zgodną z `commands/cleanup.md`/
  `commands/status.md` (nagłówek moda, numerowane sekcje, blok Output, Hard
  constraints).
- `USER_RULES.txt`: `ponytail`, `impeccable-design` dopisane do SKILL CATALOG →
  Domain; wersja podbita 3.6.0 → 3.7.0 zgodnie z konwencją commitów w historii pliku.
- `doc/commands.md`: „Six commands" → „Seven commands", pełna sekcja `/ponytail_review`.
- Manualny test: w nowej sesji poprosić o „review this diff for over-engineering" i
  sprawdzić, że agent aktywuje `skills/ponytail` bez dodatkowych podpowiedzi (opis
  skilla wystarcza jako gate — konwencja Domain-tier w tym repo).

CoVe: zastosowano (5 pytań weryfikacyjnych: czy Cursor wspiera plugin-runtime obu
projektów?, czy impeccable powinien być globalny czy per-projekt?, gdzie żyje
"always-on" ponytail w architekturze tego repo?, czy instalacja CLI impeccable może
być automatyczna?, czy wymaga to bootstrap-agents-md/AGENTS.default.md zmian? — nie,
żaden z projektów nie dotyka verify commands).

---

## Wdrożono

Wdrożono: `skills/ponytail/SKILL.md`, `skills/impeccable-design/SKILL.md`,
`commands/ponytail_review.md`, wpis w `USER_RULES.txt` (STATIC PRINCIPLES + SKILL
CATALOG, wersja 3.7.0), sekcja `/ponytail_review` w `doc/commands.md`.
