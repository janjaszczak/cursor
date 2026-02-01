# Analiza: agent/skill do utrzymywania project rules oraz agent do tworzenia agentów/skilli

**Punkt wyjścia:** `cursor-rules-principles.md`  
**Kontekst:** dokumentacja Cursor (project rules w `.cursor/rules/`, MDC, typy Always/Auto Attached/Agent Requested/Manual).

---

## 1. Stan obecny

### 1.1 Zasady z cursor-rules-principles.md

- **Prefiksy:** 000 (core), 100 (environments), 200 (security), 300 (deploy), 400 (versioning), 500 (api-tests).
- **Zasady:** jedna odpowiedzialność na plik, ~&lt;50 linii; frontmatter `description`, `alwaysApply`, opcjonalnie `globs`.
- **Agent** odpowiedzialny za dokumentację i rules: do utworzenia (~/.cursor/agents/).
- **SKILL** do zarządzania rules: do utworzenia; przy tworzeniu korzystać z tego pliku.

### 1.2 Istniejące agenci (istotni)

| Agent | Opis | Zakres rules? |
|-------|------|----------------|
| **documentation-specialist** | Docs, README, runbooki; preferuje canonical docs | Nie – brak „project rules” w opisie |
| **verifier** | Weryfikacja pracy, testy, hygiene pass (orphan files, doc consolidation) | Nie – hygiene dotyczy docs/scripts, nie `.cursor/rules/` |
| **hygiene** | Audyt nowych/zmienionych plików, KEEP/MOVE/MERGE/DELETE, canonical locations | Nie – docs/, scripts/, temp; brak `.cursor/rules/` |

### 1.3 Istniejące skille (Cursor meta)

| Skill | Zakres |
|-------|--------|
| **create-rule** | Tworzenie *nowych* reguł: format .mdc, frontmatter, best practices, &lt;50 linii |
| **create-skill** | Tworzenie nowych skilli: struktura SKILL.md, opis, trigger scenarios |
| **create-subagent** | Tworzenie nowych agentów: .md w .cursor/agents lub ~/.cursor/agents |

### 1.4 Dokumentacja i komendy

- **doc/rules.md** – opis reguł projektu, typy (global vs context-specific), best practices.
- **doc/configuration.md** – wzmianka o `.cursor/rules/`, lista 6 reguł (next-stack, python-backend, …).
- **commands/cleanup.md** – audyt docs/scripts/temp; **nie** obejmuje `.cursor/rules/`.
- **commands/retro.md** – propozycje PROJECT RULES jako patche do `${PROJECT_RULES_DIR}/*.mdc`, prefiksy 000/050/100/200/900.

### 1.5 Luka

- **Utrzymywanie project rules** (audyt `.cursor/rules/`, spójność z prefiksami z principles/retro, aktualizacja doc/rules.md, usuwanie duplikatów, propozycje MERGE/rename) **nie jest** przypisane do żadnego agenta ani do cleanup.
- **create-rule** dotyczy *tworzenia* reguł, nie *utrzymywania* zestawu reguł (konsystencja, konwencja nazewnictwa, sync z doc).

---

## 2. Dokumentacja Cursor (aktualna)

- Rules w `.cursor/rules/`, format MDC, frontmatter: `description`, `globs`, `alwaysApply`.
- Typy: Always, Auto Attached (globs), Agent Requested (description), Manual (@ruleName).
- Zagnieżdżone katalogi `.cursor/rules/` w podkatalogach – do scopowania.
- Tworzenie: New Cursor Rule, Cursor Settings &gt; Rules; generowanie z konwersacji: /Generate Cursor Rules.

**Spójność z cursor-rules-principles.md:**  
Principles dodają **konwencję prefiksów numerycznych** (000–500) i **jedną odpowiedzialność na plik** – to uzupełnienie oficjalnej dokumentacji, nie konflikt.

---

## 3. Opcje: utrzymywanie project rules

### 3.1 Opcja A: Rozszerzyć documentation-specialist

- **Zmiana:** W opisie i w instrukcjach dodać: utrzymywanie project rules (audyt `.cursor/rules/`, konwencja prefiksów z cursor-rules-principles.md / retro, sync doc/rules.md).
- **Plusy:** Jeden agent „dokumentacja + rules”; mniej artefaktów.
- **Minusy:** Agent już obejmuje docs, README, runbooki, skrypty; poszerzenie może rozmyć odpowiedzialność.

### 3.2 Opcja B: Rozszerzyć hygiene

- **Zmiana:** W audycie dodać sekcję `.cursor/rules/`: prefiksy, duplikaty treści, propozycje MERGE/rename; aktualizacja doc/rules.md.
- **Plusy:** Hygiene już robi audyt plików i propozycje KEEP/MOVE/MERGE/DELETE; spójne z „post-work order”.
- **Minusy:** Hygiene jest „po pracy” (cleanup); utrzymanie rules to także „convention maintenance” niezależnie od cleanup.

### 3.3 Opcja C: Dedykowany agent (rules-keeper / project-rules-maintainer)

- **Zmiana:** Nowy agent w ~/.cursor/agents/, description np.: „Maintains project rules: audit .cursor/rules/, prefix convention (cursor-rules-principles.md), sync doc/rules.md. Use when updating or auditing project rules.“
- **Plusy:** SRP; jasny trigger; można go wywołać bez mieszania z docs/hygiene.
- **Minusy:** Dodatkowy plik agenta; część zadań (doc/rules.md) pokrywa się z documentation-specialist.

### 3.4 Opcja D: Skill maintain-project-rules + wybrany agent

- **Skill:** Procedura audytu reguł (lista .mdc, sprawdzenie prefiksów, duplikaty, propozycje, sync doc/rules.md); źródło prawdy: cursor-rules-principles.md + commands/retro.md (prefiksy).
- **Agent:** documentation-specialist **lub** dedykowany rules-keeper – w opisie „Use skill maintain-project-rules when…”.
- **Plusy:** Skill reusable (komenda, inny agent, ręczne wywołanie); jeden źródłowy opis procesu.
- **Minusy:** Trzeba utworzyć skill i zaktualizować (lub dodać) agenta.

---

## 4. Rekomendacja: utrzymywanie project rules

1. **Wprowadzić skill `maintain-project-rules`** (np. w ~/.cursor/skills/):
   - Wejście: cursor-rules-principles.md (+ opcjonalnie commands/retro.md) jako konwencja.
   - Kroki: audyt plików w `.cursor/rules/` (prefiksy, długość, frontmatter), wykrywanie duplikatów/nakładów, propozycje MERGE/rename/usunięć, aktualizacja doc/rules.md.
   - Output: raport + propozycje (bez wykonywania destrukcyjnych zmian bez potwierdzenia).

2. **Przypisać utrzymanie rules do jednego agenta** – **rekomendacja: rozszerzyć documentation-specialist**:
   - W description dodać: „… and project rules (.cursor/rules/). Use when updating docs, runbooks, or auditing/maintaining project rules.“
   - W instrukcjach: punkt o utrzymaniu rules (audyt, konwencja prefiksów, doc/rules.md) z użyciem skillu maintain-project-rules gdy dostępny.
   - **Alternatywa:** jeśli wolisz ścisły SRP – zamiast tego **dedykowany agent rules-keeper** z tym samym skilliem; wtedy documentation-specialist nie rozszerzamy o rules.

3. **Opcjonalnie rozszerzyć commands/cleanup.md:** sekcja 2.4 „Project rules“: krótki audyt `.cursor/rules/` (prefiksy, płaska struktura), z odesłaniem do skillu/agenta maintain-project-rules.

---

## 5. Agent do tworzenia agentów i/lub skilli

### 5.1 Stan

- **create-subagent**, **create-skill**, **create-rule** to **skille** – użytkownik (lub główny agent) wywołuje je w konwersacji („chcę stworzyć regułę/skill/agenta”).
- Nie ma osobnego **agenta** o description „Use when creating new agents, skills, or rules”.

### 5.2 Opcje

- **Opcja 1: Nie tworzyć agenta „creator”.**  
  Delegowanie do skilli create-rule / create-skill / create-subagent wystarcza; użytkownik wybiera kontekst („stwórz regułę” → create-rule).

- **Opcja 2: Agent „meta“ (np. creator / cursor-meta).**  
  Description np.: „Creates or updates Cursor artifacts: project rules, skills, and agents. Use when the user wants to create or modify rules (.cursor/rules/), skills (SKILL.md), or agents (.cursor/agents/). Dispatches to create-rule, create-skill, create-subagent as needed.“  
  **Plus:** jeden punkt wejścia („chcę dodać regułę/skill/agenta”). **Minus:** dodatkowy agent; możliwa redundancja jeśli użytkownik i tak wskazuje konkretny skill.

### 5.3 Rekomendacja

- **Nie wprowadzać** dedykowanego agenta „creator” na start. Skille create-rule, create-skill, create-subagent są wystarczające; w user rules już jest router (create-rule, create-skill, create-subagent) przy „Cursor meta / ops”.
- **Opcjonalnie później:** jeśli często pojawia się potrzeba „stwórz mi coś w Cursorze (reguła/skill/agent)” bez wskazania typu – wtedy dodać agenta cursor-meta/creator z krótkim promptem i odwołaniami do tych trzech skilli.

---

## 6. Podsumowanie działań

| Działanie | Priorytet | Uwagi |
|-----------|-----------|--------|
| Skill **maintain-project-rules** | Wysoki | Audyt .cursor/rules/, prefiksy, doc/rules.md; źródło: cursor-rules-principles.md (+ retro) |
| Rozszerzyć **documentation-specialist** o scope „project rules“ | Wysoki | Albo ten agent + skill, albo dedykowany rules-keeper + skill |
| Opcjonalnie: sekcja **cleanup** „Project rules“ | Niski | Krótki audyt w /cleanup, link do skillu/agenta |
| **Nie** dodawać na razie agenta „creator“ | – | Skille create-* wystarczą; ewentualnie później cursor-meta |
| Zaktualizować **doc/rules.md** lub **doc/configuration.md** | Średni | Wzmianka o konwencji prefiksów i (po wdrożeniu) o skillu/agencie do utrzymania rules |

---

## 7. Weryfikacja

- Po wdrożeniu skillu: wywołać „audyt project rules” w repo z `.cursor/rules/` i sprawdzić, czy raport zawiera prefiksy i propozycje.
- Po rozszerzeniu agenta: wywołać documentation-specialist z prośbą o audyt/utrzymanie project rules i sprawdzić, czy odwołuje się do konwencji i doc/rules.md.

CoVe: zastosowano (4 pytania weryfikacyjne).

---

## Wdrożono

Wdrożono: rules-keeper (agent), maintain-project-rules (skill), sekcja cleanup 2.4, odwołania w retro, placement w cursor-rules-principles.
