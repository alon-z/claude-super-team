---
name: linear-sync
description: Sync .planning/ artifacts to Linear. Creates/updates initiative, projects, milestones, documents, and issues from PROJECT.md, ROADMAP.md, and PLAN.md files. Sub-commands - init (create/connect Linear initiative), projects (sync phases), milestones (sync waves), docs (sync documentation), issues [phase] (create/update issues), status (show sync state). Use when user wants to sync planning artifacts to Linear, create Linear issues from plans, or check Linear sync status.
argument-hint: "[init | projects | milestones | docs | issues [phase] | status]"
allowed-tools: Read, Write, Edit, Bash(shasum *), Glob, Grep, AskUserQuestion
---

# Linear Sync

Sync `.planning/` directory artifacts to Linear for team tracking.

This skill is the **orchestrator** -- it reads `.planning/` files, computes what needs syncing, and delegates all Linear operations to the `linear-cli` skill. This skill never calls the Linear CLI directly. It prepares the full context (names, descriptions, IDs, etc.) and tells `linear-cli` exactly what to create, update, or query.

## Hierarchy Mapping

| Planning Artifact | Linear Entity | Relationship |
|---|---|---|
| PROJECT.md | Initiative | The product idea |
| ROADMAP.md phases | Projects | Phases of work within the initiative |
| PLAN.md waves | Milestones | Sequential checkpoints within a project |
| PLAN.md tasks | Issues + Sub-issues | Actual work items within a project + milestone |

## State File

Maintain `.planning/LINEAR-SYNC.json` to track mappings between local entities and Linear IDs:

```json
{
  "version": 2,
  "team": "ENG",
  "initiative": { "id": "init_abc123", "name": "My Product Idea" },
  "projects": {
    "01-foundation": { "id": "proj_def456", "name": "Data Foundation", "synced_at": "2026-02-08T12:00:00Z" }
  },
  "milestones": {
    "01-foundation": {
      "wave-1": { "id": "ms_ghi789", "name": "Project scaffolding and database setup", "synced_at": "2026-02-08T12:00:00Z" },
      "wave-2": { "id": "ms_jkl012", "name": "Auth middleware and route protection", "synced_at": "2026-02-08T12:00:00Z" }
    }
  },
  "documents": {
    "PROJECT.md": { "id": "doc_aaa111", "synced_at": "2026-02-08T12:00:00Z", "content_hash": "abc..." }
  },
  "issues": {
    "01-01-PLAN.md": {
      "id": "ENG-45",
      "project_key": "01-foundation",
      "milestone_key": "wave-1",
      "sub_issues": [{ "id": "ENG-46", "title": "Initialize project scaffolding" }],
      "synced_at": "2026-02-08T12:00:00Z"
    }
  }
}
```

Never auto-commit this file. Never auto-delete from Linear.

## Argument Routing

| Argument | Sub-command |
|----------|------------|
| `init` | Init -- create/connect Linear initiative, write LINEAR-SYNC.json |
| `projects` | Projects -- sync ROADMAP.md phases to Linear projects within the initiative |
| `milestones` | Milestones -- sync PLAN.md waves to Linear milestones within each project |
| `docs` | Docs -- sync core .planning/ files as Linear documents on the initiative |
| `issues` | Issues -- create/update issues from all PLAN.md files |
| `issues N` | Issues -- create/update issues for phase N only |
| `status` or empty | Status -- show sync state, detect drift, recommend actions |

## Setup Checks

Run before every sub-command:

1. Verify `.planning/PROJECT.md` exists. If missing: "Run `/new-project` first."
2. Verify `linear-cli` skill is available. If missing: "Install the `linear-cli` skill first."
3. Check if `.planning/LINEAR-SYNC.json` exists
4. Check if `.planning/ROADMAP.md` exists (required for projects/milestones/issues)
5. Parse `$ARGUMENTS` to determine routing

## Init

Create or connect Linear initiative and initialize state file.

1. If LINEAR-SYNC.json already exists with initiative, AskUserQuestion: re-sync, reconnect, or cancel
2. Read `.planning/PROJECT.md`, parse project name and description
3. Tell `linear-cli` to list available teams. If one team use it, if multiple AskUserQuestion to pick
4. AskUserQuestion: create new or connect existing initiative?
   - **Create new:** Tell `linear-cli` to create an initiative named "{name}" with description "{description}". Capture the initiative ID from the result.
   - **Connect existing:** Tell `linear-cli` to list initiatives. Present options via AskUserQuestion, user picks. Capture the initiative ID.
5. Write `.planning/LINEAR-SYNC.json` with version 2, team, initiative info, empty projects/milestones/documents/issues
6. If ROADMAP.md exists suggest `/linear-sync projects`, otherwise suggest `/create-roadmap` first

## Projects

Sync ROADMAP.md phases to Linear projects within the initiative.

**Requires:** LINEAR-SYNC.json with initiative ID, ROADMAP.md exists

1. Read `.planning/ROADMAP.md`, parse all phases (number, name, goal, success criteria)
2. **Skip decimal sub-phases** (e.g., 1.1, 4.2) -- these are quick-plan insertions and should not become Linear projects. Only whole-number phases (01, 02, 03...) are synced as projects. Issues from sub-phase PLAN.md files are folded into the parent phase's project.
3. Read LINEAR-SYNC.json `projects` to get existing mappings
4. Compute the delta:
   - **New phases** (in roadmap but not in sync state)
   - **Changed phases** (in both but name/description differs)
   - **Unchanged phases** (skip)
   - **Orphaned** (in sync state but removed from roadmap)
5. Tell `linear-cli` to create/update projects within the initiative. Provide the full details for each.

   **Naming:** Use the phase name only, without the phase number prefix. Projects are ongoing workstreams, not sequential steps.

   **Description limit:** Linear project descriptions are capped at **255 characters**. Condense the phase goal into a single sentence. Do not include success criteria in the description -- those belong in a linked document or milestone descriptions.

   Example:

   > Create the following projects on team {team}, within initiative {initiative_id}:
   > 1. Name: "Data Foundation", Description: "Set up project scaffolding, CI pipeline, base data models, and dev environment.", Status: Planned
   > 2. Name: "Form Builder", Description: "Build the drag-and-drop form editor with field types, validation, and preview.", Status: Planned
   >
   > Update the following project:
   > - ID: proj_def456, new name: "Dashboard & Responses", new description: "..."

   **Status mapping:** unplanned = Planned, planned/in-progress = In Progress, has SUMMARY = Completed

5. Capture returned IDs from `linear-cli` output
6. Report orphaned projects but DO NOT delete them
7. Update LINEAR-SYNC.json with new/updated project IDs and timestamps

After syncing, suggest `/linear-sync milestones` if PLAN.md files exist.

## Milestones

Sync PLAN.md waves to Linear milestones within each project.

**Requires:** LINEAR-SYNC.json with projects synced, PLAN.md files exist

1. For each project (whole-number phase), read all PLAN.md files in that phase directory. Also include PLAN.md files from any decimal sub-phase directories that belong to this parent (e.g., phase 1.1 plans fold into the phase 01 project).
2. Group plans by wave number
3. For each wave, derive a meaningful milestone name:
   - Read the objectives/names from all plans in that wave
   - Compose a concise descriptive name (e.g., plans "Set up Next.js" + "Configure database" -> "Project scaffolding and database setup")
4. Read LINEAR-SYNC.json `milestones` to get existing mappings
5. Compute the delta (new/changed/unchanged/orphaned waves per project)
6. Tell `linear-cli` to create/update milestones on the corresponding project. Example:

   > Create the following milestones on project {project_id}:
   > 1. Name: "Project scaffolding and database setup" (sort order: 1)
   > 2. Name: "Auth middleware and route protection" (sort order: 2)
   > 3. Name: "API integration and validation" (sort order: 3)
   >
   > Update the following milestone:
   > - ID: ms_ghi789, new name: "Project scaffolding, database, and seed data"

   Milestones are ordered by wave number (wave 1 first, then wave 2, etc.)

7. Capture returned IDs from `linear-cli` output
8. Report orphaned milestones but DO NOT delete them
9. Update LINEAR-SYNC.json under `milestones.{phase-key}.{wave-N}` with IDs and timestamps

After syncing, suggest `/linear-sync issues` to create issues.

## Docs

Sync core planning files as Linear documents.

**Requires:** LINEAR-SYNC.json with initiative ID

**Files to sync:** PROJECT.md, ROADMAP.md, REQUIREMENTS.md, STATE.md (only those that exist in `.planning/`)

1. For each file, compute content hash via `shasum -a 256`
2. Compare against LINEAR-SYNC.json stored `content_hash`:
   - **Hash matches:** skip (unchanged)
   - **Hash differs or not tracked:** mark for sync
3. Tell `linear-cli` to create/update documents on the initiative. Provide full details. Example:

   > Create a new document on initiative {initiative_id}:
   > - Title: "My Product Idea - PROJECT.md", content from file `.planning/PROJECT.md`
   >
   > Update existing document {doc_id}:
   > - New content from file `.planning/ROADMAP.md`

4. Capture returned document IDs
5. Update LINEAR-SYNC.json with document IDs, timestamps, and new content hashes
6. Report results: "PROJECT.md (created), ROADMAP.md (updated), STATE.md (unchanged)"

## Issues

Create/update Linear issues from PLAN.md files. This is the most complex sub-command.

**Requires:** LINEAR-SYNC.json with projects AND milestones synced

### Process

1. **Find PLAN.md files** -- glob `.planning/phases/*/`. If `issues N` provided, filter to phase N only (zero-padded). Plans from decimal sub-phases (e.g., 1.1) are assigned to the parent phase's project.

2. **For each PLAN.md, read and decompose:**
   - Read frontmatter (phase, plan, wave, must_haves) and tasks (name, files, action, verify, done)
   - Read `references/issue-decomposition-guide.md` for decomposition strategy
   - Apply the decision matrix to determine parent/sub-issue structure:
     - 1 simple task -> single issue, no children
     - 1 complex task (5+ files) -> parent + 2-3 sub-issues by concern
     - 2-3 substantial tasks -> parent + one sub-issue per task
     - 4+ tasks -> parent + meaningful sub-issues, group where sensible
   - Prepare titles (descriptive objectives, not "Plan 01-02") and descriptions (objective, must-haves, verification)

3. **Check sync state** -- if PLAN.md already tracked in LINEAR-SYNC.json, use update mode; otherwise create mode

4. **Tell `linear-cli` to create/update the issues.** Each issue is assigned to the correct project (based on phase) and milestone (based on wave). Provide all details in a single delegation. Example:

   > Create the following issues on team {team}, project {project_id}:
   >
   > **Parent issue 1** (milestone: {milestone_id}, priority: High, labels: phase-1 wave-1, state: Backlog):
   > - Title: "Implement JWT authentication system"
   > - Description: "Objective: Set up JWT-based auth for all API endpoints.\n\nMust-haves:\n- Token generation with 1h expiry\n- Middleware for protected routes\n\nVerification: All auth tests pass, tokens validated"
   > - Sub-issues:
   >   1. "Create JWT token generation service" -- Description: "Files: src/auth/jwt.ts, src/auth/types.ts\n\nAction: Implement token generation...\n\nDone: Tokens generated with correct claims"
   >   2. "Add login API endpoint" -- Description: "Files: src/api/auth.ts\n\nAction: POST /auth/login...\n\nDone: Returns valid JWT on correct credentials"
   >   3. "Write authentication integration tests" -- Description: "..."
   >
   > **Parent issue 2** (milestone: {milestone_id}, priority: Medium, labels: phase-1 wave-2, state: Backlog):
   > - Title: "Build user profile management"
   > - ...

   **Priority mapping:** Wave 1 = High, Wave 2 = Medium, Wave 3+ = Low

   **State mapping:** no SUMMARY.md = Backlog, execution started = In Progress, SUMMARY.md exists = Done

5. **Handle completed plans** -- if SUMMARY.md exists for a plan, tell `linear-cli` to update the issue state to Done and add the summary content as a comment

6. **Capture all returned IDs** from `linear-cli` and update LINEAR-SYNC.json with issue IDs, sub-issue IDs, `project_key`, `milestone_key`, and timestamps

7. **Report results** -- "Created 3 issues (5 sub-issues) for Phase 1. Updated 2 for Phase 2."

### Idempotent Re-runs

Already-tracked issues are updated, not duplicated:
- If PLAN.md changed substantially: warn user, offer to recreate
- If minor changes: tell `linear-cli` to update title/description
- Never auto-delete sub-issues (user may have added custom ones in Linear)

## Status (Default)

Read-only overview. Does NOT call `linear-cli` -- reads only local files.

1. If no LINEAR-SYNC.json: "Not initialized. Run `/linear-sync init`." Exit.

2. Show initiative info from LINEAR-SYNC.json

3. **Project table** -- compare ROADMAP.md whole-number phases vs LINEAR-SYNC.json projects (skip decimal sub-phases):
   ```
   Projects:
   Data Foundation             synced
   Form Builder                synced
   Live Form Experience        missing
   ```

4. **Milestone table** -- compare PLAN.md waves vs LINEAR-SYNC.json milestones per project:
   ```
   Milestones:
   Data Foundation / Wave 1: Project scaffolding and database setup    synced
   Data Foundation / Wave 2: Auth middleware and route protection       synced
   Form Builder / Wave 1: Drag-and-drop field editor                   missing
   ```

5. **Document table** -- compare file hashes vs LINEAR-SYNC.json:
   ```
   Documents:
   PROJECT.md       current
   ROADMAP.md       stale (local changes detected)
   REQUIREMENTS.md  missing
   ```

6. **Issue table** -- compare .planning/phases/ vs LINEAR-SYNC.json:
   ```
   Issues:
   Phase 01: 3 plans synced (5 issues total)
   Phase 03: 4 plans NOT synced
   ```

7. **Recommendations:**
   - Projects missing -> suggest `/linear-sync projects`
   - Milestones missing -> suggest `/linear-sync milestones`
   - Documents stale -> suggest `/linear-sync docs`
   - Issues missing -> suggest `/linear-sync issues`
   - All synced -> "Everything synced."

## Success Criteria

- [ ] LINEAR-SYNC.json created with initiative connection
- [ ] Projects match ROADMAP.md phases within the initiative
- [ ] Milestones match PLAN.md waves within each project (with meaningful names)
- [ ] Documents synced with content hashing (skip unchanged)
- [ ] Issues created with intelligent parent/sub-issue structure, assigned to correct project + milestone
- [ ] Idempotent re-runs (no duplicates)
- [ ] Status shows accurate sync state across initiative/projects/milestones/issues
- [ ] All Linear operations delegated to `linear-cli`
- [ ] Never auto-commits or auto-deletes
