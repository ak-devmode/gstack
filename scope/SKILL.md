---
name: scope
version: 1.0.0
description: |
  Task scoping and skill router. Reads current context (git diff, branch, CLAUDE.md,
  open files), eliminates assumptions via two rounds of structured questions, then
  outputs a phased PRD with a full 14-skill checklist marking N/A skills with reasons.
  Creates docs/scope-{slug}/ tracking folder (scope.md + progress.md).
  Use when asked to "scope this", "plan this task", "what skills do I need", "before
  we start", "scope out", or at the beginning of any non-trivial feature or bug fix.
  Also trigger when a task touches multiple files, services, or spans more than one
  session.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Write
  - AskUserQuestion
---

# /scope — Task Scoping and Skill Router

You are acting as a structured scoping agent. Your job: read context, ask two focused
rounds of questions to eliminate assumptions, then produce a phased PRD with a ranked
skill checklist. The output goes directly into plan execution — make it actionable.

---

## Step 0 — Gather Context (run all bash blocks below, then synthesize)

Gather context before asking any questions. Never ask about something already
determinable from the environment.

```bash
# Detect project identity and branch
git remote -v 2>/dev/null | head -4
echo "---BRANCH---"
git branch --show-current 2>/dev/null || echo "unknown"
echo "---PWD---"
pwd
```

```bash
# Recent git activity (what changed, what's in flight)
git log --oneline -10 2>/dev/null || echo "no git history"
echo "---DIFF STAT---"
git diff --stat HEAD 2>/dev/null | head -30
git diff --staged --stat 2>/dev/null | head -20
```

```bash
# Open issues / work in progress indicators
ls -la docs/scope-* 2>/dev/null || echo "no active scope folders"
cat CLAUDE.md 2>/dev/null | head -60 || cat .claude/CLAUDE.md 2>/dev/null | head -60 || echo "no CLAUDE.md"
```

After running the above, synthesize what you know:
- Project (WellMed, PMG, other — from remote URL or PWD)
- Branch name and what it implies about the task
- What files have changed and in which direction
- Any active scope folders already tracking work
- Project-specific context from CLAUDE.md (compliance needs, stack, etc.)

---

## Step 1 — Round 1: Assumption Removal

Generate 5–10 questions that, if answered wrong, would fundamentally change the
approach. Fire them all in a single `AskUserQuestion` call.

**Rules for Round 1:**
- Do NOT ask about things already determinable from git diff, branch name, or CLAUDE.md
- Cover: scope boundary, timeline, prod vs exploratory, UI involvement, compliance,
  coordination with other services/people, testing strategy
- For WellMed context: ask about SATU SEHAT compliance if the change touches patient
  data, API endpoints, or health records
- For PMG context: ask about worker health data handling, regulatory requirements
- Frame questions concisely — one line each, no preamble

**Example questions (generate dynamically based on what's ambiguous):**
- "Is this greenfield or modifying existing code?"
- "Time available: single session today, or multi-session across days?"
- "Going to production this sprint, or exploratory/staging only?"
- "Does this have a UI component, or purely backend/infra?"
- "Should testing be in-scope here, or tracked separately?"
- "Does another service or team need to be coordinated?"
- "Any SATU SEHAT / regulatory compliance angle?" (WellMed only)
- "Is there a specific user-facing outcome to verify, or internal only?"

Ask only the questions where a wrong assumption would change your fundamental approach.
Skip anything already clear from context.

---

## Step 2 — Round 2: Design Refinement

After processing Round 1 answers, ask the task-specific design questions that
determine the best solution architecture, not just the right scope.

Generate questions based on task type:

**For new API/service work:**
- "Synchronous call chain or async/saga pattern?"
- "Which service owns the new data? Where does it live in the DB schema?"
- "New migration needed, or extending existing tables?"

**For UI features:**
- "Mobile-first or desktop-primary?"
- "Reuse existing component patterns or new design needed?"
- "What's the empty/error/loading state?"

**For bug fixes:**
- "Is there a regression test missing, or a genuine edge case not worth testing?"
- "Reproducible locally? Do you have a test case that triggers it?"
- "Has this affected production, or caught pre-merge?"

**For infra/devops:**
- "Terraform-managed or manual?"
- "Blue/green deployment or in-place?"
- "Rollback plan needed in scope?"

Fire Round 2 as a single `AskUserQuestion` batch (3–7 questions, task-specific).
If Round 1 already resolved the design questions (small task), skip Round 2 and
proceed directly to output.

---

## Step 3 — Determine Scale: Single vs Phased

Based on all answers, decide:

**Phased** (use phases in scope.md) if ANY of these are true:
- Task spans > 2 services
- Estimated CC work > 1 day
- Involves architecture decisions with options to evaluate
- Has a regulatory/compliance gate that blocks later work

**Single-phase** if:
- One service, one session, clear implementation path

If ambiguous after Round 1+2: ask "How much time do you have for this? [Full session
today / Just this hour / Multi-session across days]" before proceeding.

---

## Step 4 — Generate the Skill Checklist (N/A logic)

Every scope document includes ALL 14 skills. Mark each as YES, OPTIONAL, or N/A with
a reason. N/A is determined per-task, not per-project — both WellMed and PMG have
frontends and all skills are potentially applicable.

**N/A conditions:**

| Condition (task-specific) | Skills marked N/A |
|---|---|
| No UI component in this task | `/browse`, `/qa` (browser), `/qa-design-review`, `/design-consultation`, `/design-review`, `/plan-design-review` |
| No browser session needed | `/setup-browser-cookies` |
| Task is not going to prod this sprint | `/ship` → mark OPTIONAL |
| No user-visible change | `/document-release` → mark OPTIONAL |
| Small single-session task | `/retro` → mark OPTIONAL |

**Skill sequence table (fill in based on task):**

| # | Skill | Apply? | When | Notes |
|---|-------|--------|------|-------|
| 1 | /plan-ceo-review | ? | 1st | Reframe scope, catch product-level issues |
| 2 | /plan-eng-review | ? | 2nd | Architecture + data flow |
| 3 | /plan-design-review | ? | 2nd | Design audit before implementation |
| 4 | /review | ? | After impl | Catch production bugs in diff |
| 5 | /ship | ? | Final | PR creation + versioning |
| 6 | /qa | ? | After ship | Browser-based QA on staging |
| 7 | /qa-only | ? | After impl | Run test suite (go test, npm test) |
| 8 | /browse | ? | During QA | Headless browser for UI verification |
| 9 | /design-consultation | ? | Pre-impl | UI/UX design guidance |
| 10 | /design-review | ? | After impl | Design audit + fix loop |
| 11 | /qa-design-review | ? | After impl | QA-focused design review |
| 12 | /setup-browser-cookies | ? | Pre-QA | Set up browser session for QA |
| 13 | /document-release | ? | Post-ship | Sync docs with changes |
| 14 | /retro | ? | End of sprint | Retrospective |

---

## Step 5 — Write Output Files

Determine the slug: lowercase, hyphenated, 3–5 words from the task title.
Example: "wellmed-saga-handler-phase2", "pmg-report-export", "auth-refresh-bug"

```bash
# Detect docs dir — use project root docs/ or create it
ls -la docs/ 2>/dev/null | head -5 || echo "docs/ not found"
```

Create `docs/scope-{slug}/scope.md` using this exact format:

```markdown
# {Task title}
**Project:** {detected project}  **Branch:** {branch}  **Date:** {today's date}

## Context
{1–3 sentences: what this is, why it's being done, what triggered it}

## Phases
{Only if phased — omit entirely for single-phase tasks}
- Phase 1: ...
- Phase 2: ...

## Skill Sequence

| # | Skill | Apply? | When | Notes |
|---|-------|--------|------|-------|
| 1 | /plan-ceo-review | [ ] YES | 1st | {reason or N/A: reason} |
| 2 | /plan-eng-review | [ ] YES | 2nd | {reason or N/A: reason} |
| 3 | /plan-design-review | [N/A] | — | {why not applicable} |
| 4 | /review | [ ] YES | After impl | {tailored note} |
| 5 | /ship | [ ] YES | Final | {tailored note} |
| 6 | /qa | [N/A] | — | {why not applicable} |
| 7 | /qa-only | [ ] YES | After impl | {test command} |
| 8 | /browse | [N/A] | — | {why not applicable} |
| 9 | /design-consultation | [N/A] | — | {why not applicable} |
| 10 | /design-review | [N/A] | — | {why not applicable} |
| 11 | /qa-design-review | [N/A] | — | {why not applicable} |
| 12 | /setup-browser-cookies | [N/A] | — | {why not applicable} |
| 13 | /document-release | [ ] YES | Post-ship | {tailored note} |
| 14 | /retro | [ ] OPTIONAL | Sprint end | {tailored note} |

## Key Decisions Captured
{Bullet list of Round 1 + Round 2 answers that shaped this scope}
- ...
```

Create `docs/scope-{slug}/progress.md` using this exact format:

```markdown
# Progress: {Task title}

## Progress Log

| Date | Skill | Status | Notes |
|------|-------|--------|-------|
| {date} | /scope | ✓ Done | Scope created |
```

---

## Step 6 — Handoff Summary

After writing the files, output to the user:

1. The path to `scope.md` (so they can open it)
2. The recommended first skill to run (first YES in the checklist)
3. One-line summary of any N/A decisions that might surprise them
4. Whether this is single-phase or phased, and what Phase 1 ends with

Do NOT re-print the entire scope.md. Just the handoff summary above.

---

## Step 7 — Archive Check (end of task)

When the user indicates the task is complete (all YES skills done), ask:

"Task complete — archive this scope folder?
1. Yes — move to docs/archive/scope-{slug}/
2. Yes, zip — create docs/archive/scope-{slug}.zip and remove folder
3. Not yet"

If yes: move or zip accordingly. Leave no working artifacts.

---

## Behavior Rules

- **Context-first, no interview style.** Read everything before asking anything.
- **Both rounds are single batches.** Never ask one question at a time.
- **N/A is per-task, not per-project.** WellMed and PMG both have UIs.
- **No gstack branding in output files.** scope.md and progress.md look like your own docs.
- **Slug is deterministic.** Based on task title, not date. Dates go inside the file.
- **docs/ must exist.** Create it if absent — don't fail silently.
