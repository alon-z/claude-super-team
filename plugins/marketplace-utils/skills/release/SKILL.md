---
name: release
model: sonnet
description: Automate the full release ceremony -- detect changes, bump versions, update docs (CHANGELOG, README, cst-help), sync marketplace, commit, push, and open PR. Use after making changes to any plugin when ready to cut a release.
argument-hint: "[description of changes]"
allowed-tools: Read, Write, Edit, Glob, Grep, Skill, Bash(git *), Bash(test *), Bash(ls *), Bash(gh *), AskUserQuestion
disable-model-invocation: true
context:
  - "!`cat README.md`"
  - "!`cat CHANGELOG.md`"
  - "!`git log --oneline -20`"
  - "!`cat .claude-plugin/marketplace.json`"
---

# Release

Automate the release ceremony for the plugin marketplace. Detects changed plugins, bumps versions, updates documentation, syncs the marketplace manifest, and opens a PR.

**Release description (from user):** $ARGUMENTS

## Phase 1: Detect Changes

Identify what changed since the last release.

1. Read `CHANGELOG.md` and extract the version and date from the most recent entry (first `## [x.y.z]` heading).
2. Run `git log --oneline` since that date to get commits since last release. If no date is usable, use the last 20 commits.
3. Run `git diff --name-only HEAD` against the last release tag (or use the commit range from step 2) to identify changed files.
4. Group changed files by plugin: check which `plugins/*/` paths were touched. A plugin is "changed" if any file under its directory was modified.
5. Present a summary to the user:
   - List each changed plugin and its key changes (from commit messages)
   - If `$ARGUMENTS` was provided, note it will enrich the changelog
   - Ask the user to confirm proceeding with the release via AskUserQuestion

If no plugins changed, inform the user and stop.

## Phase 2: Bump Versions

For each changed plugin:

1. Read `plugins/<name>/.claude-plugin/plugin.json`
2. Parse the current `version` field (semver: `major.minor.patch`)
3. Bump the **patch** version: increment patch by 1
4. Write the updated `plugin.json`

Then determine the marketplace root version:
- Read `.claude-plugin/marketplace.json`
- Set its `version` to match the `claude-super-team` plugin version (since it's the primary plugin). If `claude-super-team` was not changed, use the highest bumped version among changed plugins.
- Write the updated `marketplace.json` version field

Store the new root version as `NEW_VERSION` for use in later phases.

## Phase 3: Update CHANGELOG.md

1. Read `CHANGELOG.md`
2. Create a new section immediately after the header line (`# Changelog` and its description paragraph), before the first `## [...]` entry:

```
## [NEW_VERSION] - YYYY-MM-DD

### plugin-name-1
- Change summary from git log
- Another change

### plugin-name-2
- Change summary
```

3. Follow the existing format exactly:
   - Version in brackets, date in ISO format
   - Group by plugin name as `### plugin-name`
   - Each change as a bullet point
   - Summarize from git log messages; enrich with `$ARGUMENTS` if provided
   - Do NOT repeat the full commit hash or prefix -- write human-readable summaries
4. Write the updated `CHANGELOG.md`

## Phase 4: Update README.md

Check if documentation updates are needed:

1. Read `README.md` (already in context)
2. Scan for command/skill tables (look for markdown tables with columns like Command, Description)
3. List all skill directories: `plugins/*/skills/*/`
4. Compare skill directories against README tables to detect:
   - New skills not yet in README
   - Removed skills still listed in README
   - Changed skill descriptions (read SKILL.md frontmatter `description` field and compare)

If changes are found:
- Add new skill rows to the appropriate plugin table
- Remove rows for deleted skills
- Update descriptions that changed
- Check if the "How It Works" section needs updates for workflow changes

If nothing changed, skip this phase entirely -- do not touch README.md.

## Phase 5: Update cst-help

Only if `claude-super-team` was among the changed plugins:

1. Read `plugins/claude-super-team/skills/cst-help/SKILL.md`
2. Read `plugins/claude-super-team/skills/cst-help/references/workflow-guide.md`
3. Read `plugins/claude-super-team/skills/cst-help/references/troubleshooting.md`
4. Detect what changed in `claude-super-team`:
   - Were new skills added? (new directories under `plugins/claude-super-team/skills/`)
   - Were existing skill behaviors changed? (check git diff for SKILL.md modifications)
5. If changes are relevant to cst-help:
   - Update the skill reference section in SKILL.md
   - Update workflow-guide.md with new workflow patterns
   - Update troubleshooting.md with new entries or updated "When to Use Each Skill"
6. If nothing relevant changed, skip -- do not touch cst-help files.

If `claude-super-team` was NOT changed, skip this phase entirely.

## Phase 6: Sync Marketplace

Invoke the marketplace sync to align all plugin.json versions with marketplace.json:

```
/marketplace-manager sync
```

Use the Skill tool to invoke this. This ensures marketplace.json entries have correct versions, descriptions, and metadata from each plugin.json.

## Phase 7: Commit, Push, PR

### 7a. Stage files

Stage only the files modified by this release process. Use specific file paths -- never `git add .` or `git add -A`:

- All modified `plugin.json` files (one per changed plugin)
- `.claude-plugin/marketplace.json`
- `CHANGELOG.md`
- `README.md` (only if modified in Phase 4)
- `plugins/claude-super-team/skills/cst-help/SKILL.md` (only if modified in Phase 5)
- `plugins/claude-super-team/skills/cst-help/references/workflow-guide.md` (only if modified)
- `plugins/claude-super-team/skills/cst-help/references/troubleshooting.md` (only if modified)

### 7b. Create release branch and commit

```bash
git checkout -b release/vNEW_VERSION
git add <specific files>
git commit -m "[marketplace-utils] (release): Bump to vNEW_VERSION

<summary of changes per plugin from changelog>"
```

### 7c. Push and open PR

Derive the PR title from the commit messages included in this release, following the repository's commit convention `[plugin] (type): Description`. Rules:

1. If only one plugin changed, use: `[plugin-name] (release): Concise summary of changes (vNEW_VERSION)`
2. If multiple plugins changed, use: `[claude-super-team] (release): Concise summary of main changes (vNEW_VERSION)`
3. The summary must describe *what* changed (from the git log), not just "bump version". Keep it under 70 characters total.
4. Examples:
   - `[claude-super-team] (skill): Add brainstorm and improve execute-phase routing (v1.0.25)`
   - `[marketplace-utils] (config): Fix audit sync and add release skill (v1.0.3)`

```bash
git push -u origin release/vNEW_VERSION
gh pr create --title "<derived title per rules above>" --body "<changelog section as PR body>"
```

The PR body should include the full changelog section created in Phase 3, formatted as markdown.

### 7d. Report

Print the PR URL and a summary of everything that was done:
- Plugins bumped and their new versions
- Files modified
- PR link
