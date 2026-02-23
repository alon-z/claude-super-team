# Project Writing Guide

Synthesize all context into `.planning/PROJECT.md` using the template from `assets/project.md`.

**For greenfield projects:**

Initialize requirements as hypotheses:

```markdown
## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] [Requirement 1]
- [ ] [Requirement 2]
- [ ] [Requirement 3]

### Out of Scope

- [Exclusion 1] — [why]
- [Exclusion 2] — [why]
```

All Active requirements are hypotheses until shipped and validated.

**For brownfield projects (codebase map exists):**

Infer Validated requirements from existing code:

1. Read `.planning/codebase/ARCHITECTURE.md` and `STACK.md`
2. Identify what the codebase already does
3. These become the initial Validated set

```markdown
## Requirements

### Validated

- ✓ [Existing capability 1] — existing
- ✓ [Existing capability 2] — existing
- ✓ [Existing capability 3] — existing

### Active

- [ ] [New requirement 1]
- [ ] [New requirement 2]

### Out of Scope

- [Exclusion 1] — [why]
```

**Key Decisions:**

Initialize with any decisions made during questioning:

```markdown
## Key Decisions

| Decision                  | Rationale | Outcome   |
| ------------------------- | --------- | --------- |
| [Choice from questioning] | [Why]     | — Pending |
```

**Last updated footer:**

```markdown
---

_Last updated: [date] after initialization_
```

Do not compress. Capture everything gathered.

**Save PROJECT.md:**

```bash
mkdir -p .planning
```

Write the file to `.planning/PROJECT.md`.

**If git was initialized by this skill (new repo):** Commit automatically:

```bash
git add .planning/PROJECT.md
git commit -m "$(cat <<'EOF'
docs: initialize project

[One-liner from PROJECT.md What This Is section]
EOF
)"
```

**If git already existed (existing repo):** Do NOT commit. Tell the user:

```
Created .planning/PROJECT.md

To commit when ready:
  git add .planning/PROJECT.md && git commit -m "docs: initialize project"
```
