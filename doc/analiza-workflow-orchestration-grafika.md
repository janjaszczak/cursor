# Analiza: grafika „Workflow Orchestration / Task Management / Core Principles"

**Punkt wyjścia:** prośba o analizę załączonej grafiki (checklista dot. orkiestracji
agenta kodującego) i wydanie rekomendacji co do zmian w ustawieniach tego repo
(`USER_RULES.txt`, `AGENTS.default.md`, `agents/`, `commands/`, `skills/`, `hooks.json`)
— z użyciem CoVe jako pętli weryfikującej, zgodnie z `USER_RULES.txt` → sekcja COVE.

---

## 1. Co to za grafika

Obrazek (bez logo/URL — traktowany jako zewnętrzna checklista, nie konkretny produkt)
zawiera trzy sekcje:

**Workflow Orchestration** (6 punktów): Plan Mode Default, Subagent Strategy,
Self-Improvement Loop, Verification Before Done, Demand Elegance (Balanced),
Autonomous Bug Fixing.

**Task Management** (6 punktów): Plan First (`tasks/todo.md` z checkboxami), Verify
Plan, Track Progress, Explain Changes, Document Results, Capture Lessons
(`tasks/lessons.md`).

**Core Principles** (3 punkty): Simplicity First, No Laziness, Minimal Impact.

Metodologia tej analizy: każdy z 15 punktów porównany z konkretnym plikiem/mechanizmem
w tym repo (evidence-based, cytaty ścieżek — zgodnie z `repo-grounding`), nie z pamięci.

---

## 2. Zestawienie punkt po punkcie

| # | Punkt z grafiki | Odpowiednik w tym repo | Werdykt |
|---|---|---|---|
| W1 | Plan Mode Default (3+ kroki/architektura → plan; STOP i re-plan; plan obejmuje weryfikację; specyfikacje upfront) | `USER_RULES.txt`: PLANNING, ACTIVATION ROUTER (`plan-as-contract`, `high-risk-review`, `task-planning-shrimp`); `AGENTIC LOOP` → „Stop conditions: 3 identical verify failures..." | **Pokryte, częściowo przekroczone.** Nasze stop-warunki są policzalne, nie tylko „coś idzie źle". Brakuje prostej liczbowej heurystyki „3+ kroki"; **nie rekomenduję dodania** — istniejące bramki (ryzyko/multi-file/infra) są precyzyjniejsze, a liczbowy próg wpychałby trywialne 3-krokowe zadania w planning wbrew `DEFAULT BEHAVIOR` („minimal overhead"). |
| W2 | Subagent Strategy (liberalnie, offload research/exploration, „throw more compute", jeden task/subagent) | Poziom platformy: Cursor instruuje każdego agenta „use Task tool with subagent_type=explore instead of running search commands directly" — niezależnie od `USER_RULES.txt`. W repo: `SUBAGENTS` + `agents/*.md` (debugger, test-runner, security-auditor, backend-specialist, devops, refactorer, rules-keeper, hygiene, documentation-specialist, verifier) — każdy już wąsko wyspecjalizowany | **Pokryte** (platforma + wąska specjalizacja agentów = „one task per subagent" out of the box). „Liberalnie" / „throw more compute" **odrzucone** — koliduje z `DEFAULT BEHAVIOR` (concise/minimal overhead) i z cost-tieringiem MCP z `README.md` (free-first, płatne jako escalation). Dopisanie tego do `USER_RULES.txt` naruszyłoby regułę ladder #2 („already in repo → reuse, don't rewrite"). |
| W3 | Self-Improvement Loop (po KAŻDEJ korekcie → `tasks/lessons.md`; review na starcie sesji) | `/save_memory`, `/recall_memory` (Neo4j), `/retro` (`commands/retro.md`) | **Realna luka** — mechanizm silniejszy niż płaski plik (cross-project, queryable), ale **opt-in/wsadowy**: nic nie wyzwala go automatycznie w MOMENCIE korekty; `/retro` jest na żądanie i wymaga literalnego `APPLY`. → **Rekomendacja #1 — wdrożona** (GUARDRAILS). |
| W4 | Verification Before Done (nigdy „done" bez dowodu; diff behavior; „would a staff engineer approve"; testy/logi) | `hooks/before_shell_quality_gate.py` (blokuje `git commit`/`push`/`gh pr create` przy FAIL), `hooks/grind_until_verify.py` (max 5 iteracji), `agents/verifier.md`, „Definition of Done" | **Przekroczone** — u nas wymuszone hookiem (nie tylko instrukcją agenta); fizycznie nie da się commitować/pushować bez PASS. „Diff behavior main vs zmiany" — drobny, opcjonalny niuans, **nie wdrożony** (ryzyko rozrostu 4-punktowej listy DoD dla rzadkiego przypadku). |
| W5 | Demand Elegance (pauza przy nieoczywistej/hackowatej zmianie; „czy jest czyściejszy sposób"; pomiń dla prostych fixów) | `STATIC PRINCIPLES` → ponytail ladder = **tylko dolna granica** (nie pisz więcej niż trzeba) | **Realna luka** — brak górnej granicy (nie wysyłaj czegoś co „działa", ale jest hackowate). Ladder i „elegance" to osie ortogonalne (zakres vs. jakość), nie duplikat. → **Rekomendacja #2 — wdrożona** (STATIC PRINCIPLES). |
| W6 | Autonomous Bug Fixing (zero hand-holding, „just fix it", CI bez pytania jak) | `skills/troubleshooting-rca/SKILL.md`, `agents/debugger.md` (mandatory RCA-before-fix gate), `commands/next.md` §3 (DEBUG row) + §4.2.6 („execute minimal first step immediately... do not stop at 'you should…'") | **Pokryte**, ale klauzula „nie pytaj, po prostu zrób" żyje tylko w `commands/next.md` (on-demand), nie w zawsze aktywnym `USER_RULES.txt`. **Nie rekomenduję przenoszenia** — ladder #2 (already in repo → reuse); DEBUG-mode routing i tak tam prowadzi, duplikat = bloat bez wartości. |
| T1 | Plan First → `tasks/todo.md` z checkboxami | `PLANNING`: „Plans need checkbox todos"; realny backlog międzysesyjny = Shrimp (`task-planning-shrimp`), nie plik | **Przekroczone** — Shrimp przechowuje status/zależności trwale; płaski plik naruszałby `DOC HYGIENE` (orphan tracking files). |
| T2 | Verify Plan — check-in przed startem | `plan-as-contract`: „Stop: wait for user approval (unless user asked 'just do it')" | **Pokryte 1:1.** |
| T3 | Track Progress | Shrimp `execute_task` / `update_task` / `verify_task` | **Przekroczone** (trwałe między sesjami, nie tylko checkbox w oknie czatu). |
| T4 | Explain Changes — podsumowanie na każdym kroku | `/next` output contract (tylko pierwsza odpowiedź); nic dla checkpointów w trakcie długiej pracy | **Realna luka** — ryzyko, że „concise by default" ześlizgnie się w ciszę podczas długich (cloud-agent) sesji. → **Rekomendacja #3 — wdrożona** (AGENTIC LOOP). |
| T5 | Document Results — sekcja review w `todo.md` | `agents/verifier.md` (wymagane „Final recommendation"), konwencja `doc/analiza-*.md` + sekcja „Wdrożono" (ten dokument jest tego przykładem) | **Przekroczone** (kanoniczna lokalizacja w `doc/`, nie plik roboczy w `tasks/`). |
| T6 | Capture Lessons po korektach | = W3 (ten sam mechanizm i ta sama luka) | patrz W3. |
| C1 | Simplicity First | KISS + ponytail ladder + „Minimal diff; match repo conventions" (`AGENTS.default.md`) | **Przekroczone.** |
| C2 | No Laziness (root cause, no temp fixes) | `troubleshooting-rca` / `debugger.md`: „Forbidden: fixing only the symptom without naming the cause" | **Przekroczone** — uwaga terminologiczna: skill „ponytail" (leniwość *wobec kodu*) ≠ „No Laziness" z grafiki (rygor *diagnozy*); różne osie, nie konflikt. |
| C3 | Minimal Impact | „Minimal diff", ponytail, DoD „No new linter/type errors in touched files" | **Przekroczone.** |

### Efekt uboczny odkryty podczas analizy (poza treścią grafiki)

| # | Obserwacja | Status |
|---|---|---|
| S1 | Treść `USER_RULES.txt` widoczna w tej sesji (wklejona do system prompt jako aktualne Settings → User Rules) to wersja **3.6.0**; HEAD repo przed tym PR to już **3.7.0**, a po tym PR **3.8.0** | **Dryf synchronizacji** — akcja **poza repo** (nie da się naprawić commitem): wklej aktualną treść `USER_RULES.txt` do Settings → Rules → User Rules, restart Cursor. Patrz `doc/rules.md` → „After edits: sync User Rules from USER_RULES.txt, restart Cursor." |

---

## 3. Rekomendacje wdrożone (ten PR)

**#1 — Self-improvement trigger (GUARDRAILS).** Domyka lukę W3/T6: koreguje user →
tej samej tury agent **proponuje** (nie zapisuje automatycznie) wpis `/save_memory`,
zamiast czekać na `/retro`. Zgodne z istniejącym „no memory-save prompt on C0/I0" (a
więc C1+ już dopuszczał prompt — brakowało tylko wyzwalacza).

**#2 — Elegance ceiling (STATIC PRINCIPLES).** Domyka lukę W5: jedno pytanie
kontrolne dla nietrywialnych/hackowatych diffów, jako górna granica komplementarna do
ladder ponytail (dolna granica). Pominięte dla oczywistych one-linerów — zgodnie z
duchem `ponytail` (nie dodawaj rytuału tam, gdzie nie trzeba).

**#3 — Checkpoint narration (AGENTIC LOOP).** Domyka lukę T4: krótka (1–2 linie)
notatka „co się zmieniło / co dalej" w naturalnych punktach przerwania podczas
długich/wieloetapowych prac, nie tylko na końcu. Długość wciąż ograniczona przez
„Concise by default" — to punkt kontrolny, nie raport.

Diff (już w `USER_RULES.txt` na tej branchy):

```diff
-# 3.7.0 — GLOBAL USER RULES (all projects)
+# 3.8.0 — GLOBAL USER RULES (all projects)

 Laziness ladder before writing code (ponytail): ... Deep audit: skill `ponytail` or `/ponytail_review`.
+Elegance ceiling (upper bound, complements the ladder above): non-trivial or hacky-feeling diff → pause once ("cleaner way, knowing this now?"), revise before presenting; skip the check itself on obvious one-liners.

 Verify-first: ... max 5 iterations then STOP + blocker.
+
+Checkpoint narration: multi-step/long-running work → 1–2 line "what changed / what's next" at natural breakpoints (after each Shrimp task or tool-call batch), not only at the end; length still bound by "Concise by default".

 - OUTPUT CONTRACT only for structured-delivery OR C1+/I1+; no memory-save prompt on C0/I0.
+- Self-improvement trigger: C1+ user correction → same turn, propose (never auto-write) a `/save_memory` entry (type=pattern); don't wait for `/retro`.
```

---

## 4. Rozważone i odłożone (z uzasadnieniem)

| Punkt | Opcja | Decyzja |
|---|---|---|
| W1 | Dodać liczbowy trigger „3+ kroki" dla Plan Mode | **Odłożone** — istniejące bramki (`plan-as-contract`/`high-risk-review`/`task-planning-shrimp`) są precyzyjniejsze niż arbitralny licznik kroków; ryzyko nadmiernego planowania dla trywialnych zadań. |
| W2 | Wpleść „use subagents liberally / throw more compute" do SUBAGENTS | **Odrzucone** — sprzeczne z `DEFAULT BEHAVIOR` (minimal overhead) i cost-tieringiem MCP; funkcja eksploracji już domyślna na poziomie platformy Cursor. |
| W4 | Dodać „diff behavior main vs changes" do Definition of Done | **Odłożone** — marginalny zysk, ryzyko rozrostu checklisty DoD (dziś 4 punkty, zwięźle). |
| W6 | Przenieść „execute immediately, don't stop at 'you should…'" z `commands/next.md` do `USER_RULES.txt` | **Odrzucone** — już w repo (ladder #2: reuse, don't duplicate); DEBUG-mode routing w `/next` i tak tam prowadzi. |
| T1/T6 | Wprowadzić płaskie `tasks/todo.md` / `tasks/lessons.md` | **Odrzucone** — Shrimp + Neo4j memory już są nadzbiorem tej funkcjonalności (trwałość między sesjami, strukturalne encje/relacje); powrót do plików naruszyłby `DOC HYGIENE`. |

---

## 5. Podsumowanie działań

| Działanie | Priorytet | Status |
|---|---|---|
| Self-improvement trigger w GUARDRAILS | Wysoki | **Wdrożono** |
| Elegance ceiling w STATIC PRINCIPLES | Wysoki | **Wdrożono** |
| Checkpoint narration w AGENTIC LOOP | Średni | **Wdrożono** |
| Bump `USER_RULES.txt` 3.7.0 → 3.8.0 | Wysoki (mechaniczne, wymagane konwencją) | **Wdrożono** |
| Zsynchronizować Settings → User Rules (IDE) z repo | **Krytyczny, poza repo** | **Do wykonania przez użytkownika** — wklej treść `USER_RULES.txt` (3.8.0) do Settings → Rules → User Rules, restart Cursor |
| Numeryczny trigger Plan Mode „3+ kroki" | Niski | Odłożone (uzasadnienie: §4) |
| „Liberalne" subagenty / throw more compute | — | Odrzucone (uzasadnienie: §4) |
| „Diff behavior" w Definition of Done | Niski | Odłożone (uzasadnienie: §4) |
| Przeniesienie klauzuli autonomii z `/next` do USER_RULES.txt | — | Odrzucone (uzasadnienie: §4) |
| Płaskie `tasks/todo.md` / `tasks/lessons.md` | — | Odrzucone (uzasadnienie: §4) |

---

## 6. Weryfikacja

- `python scripts/quality-gate.py .` → PASS (sprawdza m.in. obecność sekcji
  `AGENTIC LOOP`, `COVE`, `SKILL CATALOG`, `Global Router`, `AGENTS.default.md` w
  `USER_RULES.txt`, długość pliku, JSON configów, `py_compile` hooków) — wynik
  wklejony w commit message / PR.
- `python scripts/test-quality-gate-hook.py` → smoke test hooka bez regresji.
- Manualna weryfikacja treści: trzy nowe linie w `USER_RULES.txt` nie zmieniają
  istniejących nagłówków sekcji (wymóg gate'a), tylko dodają zdania — zero ryzyka
  kolizji z `_check_user_rules()` w `scripts/quality-gate.py`.
- Rekomendowany manualny test funkcjonalny (do wykonania przez użytkownika po
  zsynchronizowaniu Settings): sprowokować drobną korektę w nowej sesji i sprawdzić,
  czy agent sam proponuje `/save_memory` bez czekania na `/retro`.

CoVe: zastosowano (5 pytań weryfikacyjnych: czy „Self-Improvement Loop" z grafiki ma
realny odpowiednik, czy to luka mimo istnienia `/save_memory`+`/retro`? / czy „Demand
Elegance" duplikuje ladder ponytail, czy to oś ortogonalna? / czy „liberalne"
subagenty są zgodne z filozofią „concise by default" i cost-tieringiem MCP w tym
repo, czy to konflikt? / czy wersja `USER_RULES.txt` w tej sesji zgadza się z HEAD
repo? / czy „Autonomous Bug Fixing" i „Plan Mode Default" mają już pokrycie i gdzie
ewentualnie brakuje?).

---

## Wdrożono

Wdrożono: bump `USER_RULES.txt` 3.7.0 → 3.8.0; trzy nowe linie (`Elegance ceiling` w
STATIC PRINCIPLES, `Checkpoint narration` w AGENTIC LOOP, `Self-improvement trigger`
w GUARDRAILS); ten dokument (`doc/analiza-workflow-orchestration-grafika.md`).

Nie wdrożono w repo (poza zakresem commitu, wymaga akcji użytkownika): synchronizacja
Settings → User Rules (IDE) z aktualną treścią `USER_RULES.txt`.
