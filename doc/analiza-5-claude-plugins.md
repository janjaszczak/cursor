# Analiza: „5 Claude Plugins Every Developer Needs” — przydatność dla tego repo

**Punkt wyjścia:** załączony PDF (`5-Claude-Plugins-Every-Developer-Needs`) opisujący pięć
pluginów **Claude Code** (Superpowers, Context7, Claude Mem, Caveman, Security Guidance) i
prośba o ocenę ich przydatności dla tego setupu (`~/.cursor` — single source of truth dla
**Cursora**: `USER_RULES.txt`, `AGENTS.default.md`, `agents/`, `commands/`, `skills/`,
`hooks.json`, `mcp.json`). Metodologia i format jak w poprzedniej analizie tego typu —
[`doc/analiza-ponytail-impeccable.md`](analiza-ponytail-impeccable.md) — plus web-research
(lipiec 2026) do zweryfikowania twierdzeń z PDF, bo dotyczą mechanizmów i benchmarków, które
się zmieniają.

**Zakres tej notatki:** tylko ocena + rekomendacja. Nic z sekcji 4 nie zostało wdrożone —
w przeciwieństwie do analizy ponytail/impeccable, tu nie było prośby o `wdrożenie`, tylko o
`ocenę przydatności`.

---

## 1. Co to za pluginy (z PDF, zweryfikowane)

| # | Plugin | Co robi | Źródło / licencja | Mechanizm dystrybucji |
|---|--------|---------|--------------------|------------------------|
| 1 | **Superpowers** | Metodologia inżynierska jako zestaw skilli: brainstorming (Socratic Q&A → spec), writing/executing-plans, TDD RED/GREEN, systematic-debugging, subagent-driven-development (2-etapowy review: spec compliance → code quality), git-worktrees | Community (Jesse Vincent / obra), MIT | Claude Code plugin marketplace: `/plugin marketplace add obra/superpowers-marketplace` + `/plugin install` |
| 2 | **Context7** | Wstrzykuje aktualną, wersjo-specyficzną dokumentację bibliotek (+ przykłady kodu) do kontekstu | Upstash; oficjalnie w Anthropic marketplace, MIT | **Zwykły serwer MCP** (remote HTTPS `mcp.context7.com/mcp` lub `npx @upstash/context7-mcp`) |
| 3 | **Claude Mem** | Pamięć między sesjami: przechwytuje działania, kompresuje AI-em, wstrzykuje streszczenie przy starcie sesji | Community (Alex Newman / thedotmack), Apache-2.0 | 5 lifecycle hooks Claude Code (`SessionStart`/`UserPromptSubmit`/`PostToolUse`/`Stop`/`SessionEnd`) + SQLite + Chroma vector DB |
| 4 | **Caveman** | Kompresuje odpowiedzi do telegraficznego stylu, chroniąc kod/komendy/błędy 1:1 | Community (Julius Brussee), MIT | Claude Code plugin (skill + hook auto-load na starcie sesji) |
| 5 | **Security Guidance** | Automatyczny przegląd bezpieczeństwa zmian Claude'a (regex pattern-match + 2 warstwy LLM: end-of-turn diff review, commit/push review) | **Oficjalny Anthropic**, wbudowany w Claude Code | Claude Code plugin; wymaga CLI ≥2.1.144, Python 3.8+, wywołań do `api.anthropic.com` (lub własnego gateway) |

Zgodnie z samym PDF: tylko Context7 i Security Guidance są oficjalne (Anthropic); resztę
(Superpowers, Claude Mem, Caveman) trzeba by audytować jak każdą nową zależność przed
instalacją — co i tak jest tu nieaktualne, bo **żadnego z nich nie da się zainstalować w
Cursorze 1:1**, patrz sekcja 2.

---

## 2. Ograniczenie: to są pluginy **Claude Code**, nie Cursora

Ten sam wniosek co w `doc/analiza-ponytail-impeccable.md` (sekcja 2 tamtego dokumentu),
potwierdzony teraz dla nowego zestawu pluginów:

| Mechanizm w tych pluginach | Cursor dziś |
|---|---|
| Plugin marketplace + `/plugin install`, `/plugin marketplace add`, `/reload-plugins` | **Nie istnieje w Cursorze** — to komendy CLI Claude Code, nie Cursora |
| Lifecycle hooks Claude Code: `SessionStart`, `UserPromptSubmit`, `PostToolUse`, `Stop`, `SessionEnd`, `PreCompact`, `Setup` (matcher-based, `${CLAUDE_PLUGIN_ROOT}`, `hookSpecificOutput.additionalContext`) | Cursor ma **własny, mniejszy** zestaw: `preToolUse` / `beforeShellExecution` / `beforeMCPExecution` / `stop` ([`doc/hooks.md`](hooks.md), [`hooks.json`](../hooks.json)). **Brak odpowiednika `SessionStart`/`PostToolUse`/`SessionEnd`** → nie da się odtworzyć „silent context injection przy starcie sesji” (Claude Mem) ani „warn na każdym Write/Edit” w tej samej, natywnej formie (Security Guidance) |
| Slash-commands z pluginu (`/caveman`, `/plugin`) | Cursor: własne Custom Commands (`commands/*.md`) — inny mechanizm, wymaga ręcznego odtworzenia (jak `/ponytail_review`) |
| Model-backed review calls do `api.anthropic.com` (Security Guidance) | Cursor agent **sam już jest LLM** wykonującym pracę — dodatkowe wywołanie do Anthropic API byłoby drugim, redundantnym modelem w pętli, nie funkcją Cursora |
| MCP server bundlowany z pluginem | Cursor: `mcp.json` — **to jest jedyny punkt, w którym mechanizmy się pokrywają 1:1** |

**Wniosek:** 4 z 5 pluginów (Superpowers, Claude Mem, Caveman, Security Guidance) są
architektonicznie zamknięte na Claude Code — nie da się ich „zainstalować”, tylko
(ewentualnie) ręcznie przenieść samą **ideę** do istniejących prymitywów tego repo, tak jak
zrobiono to wcześniej dla ponytail. **Context7 jest wyjątkiem** — to zwykły serwer MCP,
niezależny od Claude Code, z natywnym wsparciem dla Cursora (`~/.cursor/mcp.json`) —
potwierdzone w niezależnych źródłach: [Upstash blog](https://upstash.com/blog/context7-mcp),
[Apidog setup guide](https://apidog.com/blog/context7-mcp-server/),
[Agent Hub — lista 30+ klientów MCP](https://agent-hub.dev/mcps/context7/).

---

## 3. Ocena per plugin

| Plugin | Da się przenieść? | Co już jest pokryte w tym repo | Werdykt | Priorytet |
|---|---|---|---|---|
| **Superpowers** | Nie 1:1 (plugin runtime); idea częściowo tak (to markdown skille) | `plan-as-contract`, Plan Mode, `task-planning-shrimp` (writing/executing-plans); `troubleshooting-rca` + `agents/debugger.md` (systematic-debugging); `agents/verifier.md` + SUBAGENTS router (subagent review); AGENTS.default.md DoD + quality-gate hooki (verification-before-completion — u nas **silniej**, fizycznie wymuszone hookiem, nie tylko instrukcją) | **W większości redundantne** — ladder #2 („already in repo → reuse”) mówi nie kopiować. 2 luki opisane niżej są realne, ale opcjonalne | Niski (opcjonalnie) |
| **Context7** | **Tak — to zwykły MCP, nie plugin** | Żaden z 11 serwerów MCP (`memory`, `playwright`, `duckduckgo`, `searxng`, `github`, `grafana`, `shrimp-task-manager`, `postman`, `perplexity`, `Apify`, `browseros`) nie robi wersjo-specyficznego lookupu dokumentacji bibliotek — searxng/duckduckgo/perplexity to ogólne wyszukiwanie, nie to samo | **Realna luka, warto dodać** | **Wysoki** |
| **Claude Mem** | Nie (inny hook schema — brak `SessionStart`/`PostToolUse`/`SessionEnd` w Cursorze) | Neo4j graph memory + `mcp-memory-recall` + `mcp-neo4j-memory-ops` + `/save_memory` + `/recall_memory` — **inna filozofia** (gated/explicit vs automatic/silent), zamierzona (guardrail „no memory-save prompt on C0/I0”, „Activation gate (anti-noise)” w obu skillach memory) | **Już pokryte, świadomie inaczej** — nie dodawać drugiego backendu pamięci (SQLite+vector) równolegle do Neo4j, to złamałoby DRY i rozdzieliło źródło prawdy | — (brak akcji) |
| **Caveman** | Nie (plugin+hook Claude Code) | `USER_RULES.txt` → ROLE „Correctness > brevity. Concise by default” + laziness ladder — już wymusza zwięzłość promptowo | **Skip** — nawet w natywnym środowisku realny zysk na sesjach agentowych to ~8,5%, nie reklamowane ~65-75% (patrz sekcja 3.4) | — (brak akcji) |
| **Security Guidance** | Nie (twardy wymóg Claude Code CLI ≥2.1.144 + wywołania do `api.anthropic.com`) | `agents/security-auditor.md`, `skills/high-risk-review`, „never skip security” w ladder, + `guard-secret-write.py`/`guard-shell-secret.py`/`guard-mcp-write.py` (dla wycieku sekretów: **silniejsze** niż plugin — blokują zapis, nie tylko ostrzegają po fakcie) | W większości pokryte; **1 konkretna, przenośna idea** (deterministyczny regex-layer bez wywołania modelu) opisana w 3.5 | Średni (opcjonalnie) |

### 3.1 Superpowers — dwie realne luki (opcjonalne)

Superpowers ma 9 skilli ([lista ze źródła](https://github.com/obra/superpowers)):
`brainstorming`, `writing-plans`, `executing-plans`, `dispatching-parallel-agents`,
`requesting-code-review`, `receiving-code-review`, `using-git-worktrees`,
`finishing-a-development-branch`, `subagent-driven-development` (+ meta: `writing-skills`).
Po zmapowaniu 1:1 na istniejące skille/agenty tego repo, zostają dwie rzeczy, których
faktycznie nie ma:

1. **`brainstorming`** — Socratic-questioning *przed* planowaniem (agent aktywnie dopytuje,
   zamiast zakładać). Plan Mode + `plan-as-contract` zakładają, że wymagania są już znane;
   nic nie wymusza fazy „dopytaj, zanim zaplanujesz”. Mała, tania rzecz do rozważenia jako
   dopisek do `plan-as-contract` (nie nowy skill — ladder #6, „jedna linia wystarczy”).
2. **`using-git-worktrees`** — izolacja równoległej pracy przez `git worktree`. Nie ma tu
   odpowiednika. **UNCERTAIN:** nie zweryfikowałem, czy Cursor's Task tool (subagenty) już
   izoluje równoległe wywołania w praktyce inaczej (np. przez oddzielne konteksty rozmowy
   bez współdzielenia working directory) — zanim to dodawać, trzeba by to sprawdzić
   empirycznie; jeśli subagenty i tak nie modyfikują plików współbieżnie, to YAGNI.

Resztę (TDD, systematic-debugging, subagent review, verification-before-completion) uznaję
za już pokrytą — w części przypadków (quality-gate hooki, `guard-*` hooki) nawet mocniej,
bo wymuszone mechanicznie, nie tylko instrukcją w kontekście.

### 3.2 Context7 — rekomendacja: dodać

Jedyny kandydat z realną, tanią wartością dodaną:

- **Koszt wejścia:** zero — działa anonimowo od razu (`https://mcp.context7.com/mcp`, bez
  API key), dokładnie zgodnie z konwencją cost-tieringu z `README.md` („Free / self-hosted
  preferred as defaults”). Opcjonalny darmowy `CONTEXT7_API_KEY` tylko dla wyższych limitów.
- **Prościej niż większość z 11 istniejących serwerów** — nie wymaga Dockera (można użyć
  wpisu z samym `url`, jak `browseros`, albo `npx` jak w [przykładzie Upstash](https://upstash.com/blog/context7-mcp)), więc nie komplikuje modelu „wszystko w Dockerze” — wystarczy wpis analogiczny do `browseros` (`{"url": "https://mcp.context7.com/mcp"}`).
- **Wypełnia realną dziurę**: `python-backend`, `next-stack`, `vanilla-web`, `data-import-parsers` — te skille domenowe korzystałyby z aktualnej dokumentacji API zamiast wiedzy modelu, która bywa nieaktualna dla szybko zmieniających się bibliotek.
- Potwierdzone wsparcie Cursora w niezależnych źródłach: [mcpplaygroundonline setup guide](https://mcpplaygroundonline.com/blog/context7-mcp-server-setup-guide), [Agent Hub — 30+ klientów MCP w tym Cursor 1.0+](https://agent-hub.dev/mcps/context7/), [Augment Code MCP directory — „Does Context7 work with Cursor? Yes”](https://www.augmentcode.com/mcp/context7).

Jeśli zdecydujesz się wdrożyć, konkretne kroki (nie wykonane w tej notatce — patrz sekcja 5):
dopisać wpis do `mcp.json`, nowy `skills/mcp-context7-docs/SKILL.md` na wzór
`skills/mcp-github-ops/SKILL.md`, dopisać do `README.md` (liczba serwerów: 11→12) i
`doc/mcp.md`. To jest właśnie ten typ literówki liczby serwerów, który repo już raz łapało
(`94aff95 docs: … fix stale MCP server counts`) — więc oba miejsca trzeba zmienić razem.

### 3.3 Claude Mem — dlaczego to nie luka, tylko inna filozofia

Zweryfikowany mechanizm ([hooks-architecture](https://www.mintlify.com/thedotmack/claude-mem/hooks-architecture), [repo](https://github.com/thedotmack/claude-mem)): 5 hooków lifecycle
(`SessionStart`→wstrzyknij kontekst silently, `UserPromptSubmit`→zapisz prompt,
`PostToolUse`→kolejkuj obserwację do kompresji AI, `Stop`→podsumowanie sesji,
`SessionEnd`→cleanup), backend SQLite + Chroma vector. To wymaga hooków, których Cursor nie
ma (`SessionStart`, `PostToolUse`, `SessionEnd` nie istnieją w `doc/hooks.md`).

Nawet gdyby dało się to technicznie odtworzyć, **nie rekomenduję** równoległego backendu
pamięci: ten repo ma już Neo4j (graph, relacje PROJECT→DECISION→CONSTRAINT) + jawne komendy
`/save_memory`/`/recall_memory` + gated activation (`mcp-memory-recall`: „Do NOT run for:
single-shot Q&A…”). Dodanie SQLite+vector jako drugiego źródła prawdy złamałoby DRY i
guardrail „no memory-save prompt on C0/I0” — Claude Mem zapisuje *automatycznie i bez pytania
po każdym `PostToolUse`, co jest odwrotnością filozofii anti-noise już przyjętej tutaj.

### 3.4 Caveman — reklamowane -65% vs realne ~8,5% na pracy agentowej

To jest miejsce, gdzie PDF (i większość materiałów marketingowych) podaje liczbę, która **nie
przenosi się** na ten typ użycia. Niezależny, kontrolowany benchmark
([JetBrains AI blog, lipiec 2026](https://blog.jetbrains.com/ai/2026/07/speak-to-ai-agents-like-cavemen-tosave-tokens/))
z Caveman wymuszonym na `ON` w każdej odpowiedzi (czyli best-case, bo normalnie plugin sam
decyduje kiedy się aktywować — realne zużycie może być tylko niższe):

> „Advertised savings come from chat-style prose answers. Agentic output is different: code,
> diffs, tool invocations, and exact error strings dominate the token stream, and Caveman
> correctly leaves all of it verbatim. […] at scale the saving converges to **-8.5%** (592k to
> 542k output tokens over 82 paired tasks). The advertised -65% is off-chart.”

Innymi słowy: reklamowane 65-75% to benchmark na *prozie czatowej* (pytania-odpowiedzi), nie
na pracy agenta kodującego (diff, komendy, tool calls) — a to dokładnie profil tego repo.
Do tego: `USER_RULES.txt` już wymusza zwięzłość promptowo (ROLE, DEFAULT BEHAVIOR, ladder), za
darmo, bez zewnętrznej zależności. Dodatkowe ryzyko: Caveman kompresuje właśnie „narrację
między tool-callami” — czyli te same miejsca, gdzie ten repo wymaga konkretnej treści
(checkpoint narration, stopka CoVe, „1 key risk / 1 invalidating assumption”, sekcje
`structured-delivery`). Mogłoby to kolidować z wymogami tego repo, gdyby plugin nie
rozpoznał ich jako „substance” do zachowania.

### 3.5 Security Guidance — jedna przenośna idea (warstwa regex, bez modelu)

Zweryfikowany mechanizm ([official docs](https://code.claude.com/docs/en/security-guidance), [plugin source](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/security-guidance)): 3 warstwy —
(1) regex pattern-match na każdym Write/Edit/MultiEdit, **bez wywołania modelu**, 8 kategorii
(command injection w GH Actions, `child_process.exec`, `eval`/`new Function`,
`innerHTML`/`dangerouslySetInnerHTML`, Python `pickle`, `os.system`, …); (2) LLM diff review
na końcu tury; (3) LLM review przy commit/push. Warstwy 2-3 wymagają Claude Code + wywołania
do `api.anthropic.com` (`SECURITY_REVIEW_MODEL`) — nie da się i nie ma sensu tego odtwarzać w
Cursorze (agent Cursora już jest LLM-em robiącym review; drugie wywołanie modelu byłoby
kosztownym duplikatem, nie funkcją brakującą).

Warstwa 1 (deterministyczny regex, zero kosztu, zero modelu) jest jednak **dokładnie tym samym
wzorcem**, co już istniejący `hooks/guard-secret-write.py` (`preToolUse`, matcher `Write`) —
tylko dla innej kategorii (wzorce podatności, nie sekrety). To jest realnie przenośne, bo nie
wymaga niczego specyficznego dla Claude Code — tylko regexów i istniejącego hook-punktu.

Zanim jednak dodawać nowy hook: cieńsza, tańsza opcja (ladder #6) to po prostu dopisanie tej
samej listy 8 kategorii jako statycznej checklisty w `agents/security-auditor.md` /
`skills/high-risk-review/SKILL.md` — bez nowego mechanizmu, korzystając z tego, że
`security-auditor` i tak jest wywoływany na ryzykownych zmianach. Nowy deterministyczny hook
miałby sens tylko, jeśli w praktyce okaże się, że LLM-based `security-auditor` przepuszcza te
konkretne wzorce (czyli dowód z użycia, nie z założenia — obecnie **UNCERTAIN**, nie mam na to
dowodu ani w drugą, ani w drugą stronę).

---

## 4. Rekomendacja i priorytety

| Działanie | Priorytet | Uwagi |
|---|---|---|
| Dodać **Context7** do `mcp.json` (+ `skills/mcp-context7-docs/SKILL.md`, aktualizacja `README.md`/`doc/mcp.md`) | **Wysoki** | Jedyny plugin, który jest zwykłym MCP; zero kosztu wejścia; realna luka (żaden z 11 serwerów nie robi version-aware doc lookup) |
| Dopisać checklistę 8 kategorii podatności (z Security Guidance) do `agents/security-auditor.md` / `skills/high-risk-review/SKILL.md` | Średni | Tania, przenośna treść; nie wymaga nowego mechanizmu |
| Rozważyć dopisek „dopytaj przed planem” (Superpowers `brainstorming`) do `plan-as-contract` | Niski | Opcjonalne, jednolinijkowe |
| Nowy deterministyczny hook `guard-vulnerable-pattern-write.py` (Security Guidance layer 1) | Niski / warunkowy | Dopiero jeśli pojawi się dowód, że sam `security-auditor` (LLM) przepuszcza te wzorce |
| `using-git-worktrees` (Superpowers) | — | UNCERTAIN czy potrzebne — zweryfikować najpierw, czy Task tool subagenty już izolują pracę |
| **Nie** instalować Superpowers/Claude Mem/Caveman/Security Guidance jako pluginów | — | Architektonicznie niemożliwe w Cursorze (brak plugin runtime + inny hook schema) |
| **Nie** dodawać SQLite/vector jako drugiego backendu pamięci (Claude Mem) | — | Złamałoby DRY; Neo4j + gated commands to już świadomy, inny wybór filozofii |
| **Nie** adoptować Caveman ani jego idei jako nowego mechanizmu | — | Wartość już pokryta przez `USER_RULES.txt`; realny zysk na pracy agentowej (~8,5%) nie uzasadnia nowej zależności |

---

## 5. Rekomendowane następne kroki (czekają na Twoją decyzję)

Nic z sekcji 4 nie zostało wdrożone w tym przebiegu — to była prośba o ocenę, nie o
implementację (w przeciwieństwie do `analiza-ponytail-impeccable.md`, gdzie prośba wprost
obejmowała „decyzję jak wdrożyć”). Jeśli chcesz, żeby agent wdrożył którąkolwiek pozycję z
sekcji 4, najprostsze polecenia:

- „Wdróż Context7” → doda wpis do `mcp.json` + skill + aktualizację `README.md`/`doc/mcp.md`.
- „Dopisz checklistę Security Guidance do security-auditor” → rozszerzy
  `agents/security-auditor.md` (i/lub `skills/high-risk-review/SKILL.md`) o 8 kategorii wzorców.
- „Sprawdź, czy potrzebujemy git worktrees dla subagentów” → osobna, mała weryfikacja przed
  decyzją (dowód, nie założenie).

---

## 6. Weryfikacja

- Treść PDF (`5-Claude-Plugins-Every-Developer-Needs`) zgodna z niezależnymi źródłami dla
  wszystkich 5 pluginów — nazwy repo, licencje, komendy instalacji potwierdzone.
- Architektura tego repo (Cursor, nie Claude Code) potwierdzona z pierwszej ręki:
  [`doc/hooks.md`](hooks.md) (4 typy hooków, link do `cursor.com/docs/agent/hooks`),
  [`skills/ponytail/SKILL.md`](../skills/ponytail/SKILL.md) (`compatibility:` explicite mówi
  „Cursor has no native plugin/skill-command runtime”), `mcp.json` (11 serwerów, zliczone
  ręcznie i zgodne z `README.md`).
- Kluczowe twierdzenia zewnętrzne zweryfikowane web-search (lipiec 2026), nie z pamięci
  modelu — patrz linki inline w sekcji 3. Najważniejsza korekta: benchmark Caveman na pracy
  agentowej (~8,5%) vs reklamowane ~65-75% (chat/proza) — źródło:
  [JetBrains AI blog](https://blog.jetbrains.com/ai/2026/07/speak-to-ai-agents-like-cavemen-tosave-tokens/).
- Manualny test (do wykonania przez Ciebie, opcjonalnie): jeśli zdecydujesz się na Context7,
  po dodaniu do `mcp.json` sprawdź w nowej sesji, że fraza „use context7” albo praca w
  `python-backend`/`next-stack` faktycznie zwraca dokumentację z `context7.com`, nie ogólny
  wynik z searxng/duckduckgo.

CoVe: zastosowano (5 pytań weryfikacyjnych: czy pluginy Claude Code instalują się w Cursorze
1:1?, czy Context7 jest wyjątkiem jako zwykły MCP?, czy hook schema Cursora pozwala odtworzyć
mechanizm Claude Mem?, czy reklamowane ~65-75% oszczędności tokenów Caveman utrzymuje się na
pracy agentowej, nie tylko czacie?, czy warstwy Security Guidance są przenośne poza Claude
Code? — każde zweryfikowane web-search + istniejącymi plikami repo, nie z pamięci).

---

## Wdrożono

Wdrożono (branch `cursor/implement-context7-security-checklist`):

- `mcp.json` — wpis `context7` (URL `https://mcp.context7.com/mcp`)
- `skills/mcp-context7-docs/SKILL.md`
- `README.md`, `doc/mcp.md`, `doc/configuration.md` — liczba serwerów 12, Context7 w tierze free/URL-based
- `USER_RULES.txt` — wersja 3.9.0, `mcp-context7-docs` w SKILL CATALOG i ACTIVATION ROUTER
- `agents/security-auditor.md` — checklista 8 kategorii wzorców podatności
- `skills/high-risk-review/SKILL.md` — odnośnik do checklisty
- `skills/plan-as-contract/SKILL.md` — krok clarify-before-plan

Nie wdrożono (zgodnie z analizą): pluginy Claude Code, Claude Mem, Caveman, hook `guard-vulnerable-pattern-write.py`, git worktrees.
