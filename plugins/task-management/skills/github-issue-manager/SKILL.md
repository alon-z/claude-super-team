---
name: github-issue-manager
description: Create and maintain GitHub issues following best practices. Use when creating new issues, editing issue titles/bodies, triaging issues, managing issue metadata (labels, types, assignees), or converting task lists/backlogs into structured GitHub issues. Ensures consistent formatting, clear descriptions, proper categorization, and supports hierarchical issue structures (epics with child issues).
model: haiku
argument-hint: "[create | edit | triage | bulk-create | close]"
allowed-tools: Read, Grep, Glob, Bash(gh repo view *), Bash(gh issue create *), Bash(gh issue edit *), Bash(gh issue view *), Bash(gh issue list *), Bash(gh issue close *), Bash(gh label create *), Bash(gh label list *)
---

# GitHub Issue Manager

Maintain high-quality GitHub issues with consistent standards for titles, descriptions, labels, and metadata. Supports converting structured task documents into organized GitHub issues.

## Issue Standards

### Title Guidelines

Follow these rules for clear, searchable issue titles:

- **Sentence case** - Capitalize only the first word and proper nouns
- **No type prefixes** - Use GitHub issue labels/types, not `Bug:`, `Feature:`, `[Bug]`, etc.
- **Imperative mood for features** - "Add user authentication" not "Adding user authentication"
- **Descriptive for bugs** - Describe the symptom: "Login form crashes on Safari"
- **Specific and standalone** - Should be readable without opening the issue body

#### Good Examples

- `Login form crashes on Safari mobile`
- `Add dark mode toggle to settings`
- `API returns 500 error for bulk uploads`
- `Improve performance of search results`

#### Bad Examples

- `Bug: login bug` (has prefix, too vague)
- `[Feature] Add new feature` (has prefix, not specific)
- `Not working` (too vague)
- `Adding Dark Mode Support` (not imperative)

#### Title Cleanup Transformations

When cleaning up existing titles:

1. Remove prefixes: `Bug: X` → `X`, `[Feature] X` → `X`
2. Fix capitalization: `Add Dark Mode` → `Add dark mode`
3. Use imperative: `Adding feature X` → `Add feature X`
4. Be specific: `Problem with login` → `Login form crashes on submit`
5. Translate non-English titles to English if repository is English-based

### Issue Types and Labels

**GitHub Issue Types** (if repository uses them):

| Type        | Use For                                    |
| ----------- | ------------------------------------------ |
| `Bug`       | Something not working as expected          |
| `Feature`   | New capability or enhancement              |
| `Question`  | Questions about usage or implementation    |
| `Task`      | Internal tasks, chores, or maintenance     |
| `Epic`      | Large feature spanning multiple issues     |

**Common Labels** (use sparingly, 1-3 per issue):

| Label              | Use For                                  |
| ------------------ | ---------------------------------------- |
| `good first issue` | Well-scoped issues for new contributors  |
| `needs info`       | Requires additional information          |
| `priority: high`   | Critical issues needing immediate attention |
| `priority: low`    | Nice-to-have improvements                |
| `documentation`    | Documentation improvements               |
| `performance`      | Performance-related issues               |
| `security`         | Security vulnerabilities or concerns     |
| `dependencies`     | Dependency updates                       |

**Automation Labels** (do not apply manually):
- CI/CD labels (e.g., `deploy`, `release`)
- Bot-managed labels (e.g., `stale`, `wontfix`)
- Auto-generated labels from workflows

### Issue Body Standards

#### Bug Reports

Include these sections for bug reports:

1. **Description** - Clear explanation of what's wrong
2. **Steps to Reproduce**
   - Step 1
   - Step 2
   - Step 3
3. **Expected Behavior** - What should happen
4. **Actual Behavior** - What actually happens
5. **Environment** - Browser/OS/version when relevant
6. **Screenshots/Videos** - Visual evidence when applicable
7. **Additional Context** - Any other relevant information

Example:
```markdown
## Description
The login form crashes when submitting credentials on Safari mobile.

## Steps to Reproduce
1. Open login page on Safari (iOS 17)
2. Enter valid credentials
3. Click "Sign In" button

## Expected Behavior
User should be logged in and redirected to dashboard

## Actual Behavior
Page becomes unresponsive and requires refresh

## Environment
- Browser: Safari 17.1 (iOS 17.2)
- Device: iPhone 14 Pro
- App Version: 2.3.1
```

#### Feature Requests

Include these sections for feature requests:

1. **Problem Statement** - What problem does this solve?
2. **Proposed Solution** - How should it work?
3. **Alternatives Considered** - Other approaches evaluated
4. **Use Cases** - Specific scenarios where this helps
5. **Implementation Notes** - Technical considerations (optional)

Example:
```markdown
## Problem Statement
Users need to switch between light and dark modes based on their preference and time of day.

## Proposed Solution
Add a theme toggle in the settings page with three options:
- Light
- Dark
- Auto (follows system preference)

## Alternatives Considered
- Auto-only based on time of day (less user control)
- Browser extension (requires extra installation)

## Use Cases
- Users working late prefer dark mode
- Users with visual sensitivities need specific themes
- Presentation mode benefits from theme control
```

#### Questions

Keep questions focused and include:

1. **Context** - What you're trying to accomplish
2. **What You've Tried** - Research/attempts made
3. **Specific Question** - Clear, focused question

## Triage Workflow

### Creating New Issues

When creating issues:

1. Choose appropriate title following guidelines above
2. Select correct issue type
3. Write comprehensive description using templates above
4. Add 1-3 relevant labels
5. Assign to appropriate team/person if known
6. Link to related issues or PRs if applicable

### Reviewing Existing Issues

When triaging or cleaning up issues:

1. Verify title follows standards (clean up if needed)
2. Check if description has sufficient information
3. Add `needs info` label and comment if details missing
4. Add `good first issue` if appropriate for newcomers
5. Update labels to match current state
6. Close if no longer relevant or duplicate
7. Link related issues

### Handling Stale Issues

For issues without activity:

1. Review if still relevant to current codebase
2. Close with explanation if no longer applicable
3. Request updates if waiting on information
4. Update description if context has changed
5. Re-prioritize based on current roadmap

## GitHub CLI Usage

Use `gh` command for issue operations:

```bash
# Create new issue
gh issue create --title "Issue title" --body "Description"

# Create with label and assignee
gh issue create --title "Fix login bug" --label "bug" --assignee @me

# Edit existing issue
gh issue edit 123 --title "New title"

# Add labels
gh issue edit 123 --add-label "priority: high"

# Close issue
gh issue close 123 --comment "Fixed in PR #456"

# View issue details
gh issue view 123

# List issues
gh issue list --label "bug" --state open
```

## Quality Checklist

Before submitting or updating an issue, verify:

- [ ] Title is in sentence case
- [ ] Title has no type prefix
- [ ] Title is specific and descriptive
- [ ] Description follows appropriate template
- [ ] Labels are accurate and minimal (1-3)
- [ ] Type/category is set correctly
- [ ] Related issues/PRs are linked
- [ ] Screenshots/examples included if helpful
- [ ] Environment details included for bugs

## Common Patterns

### Converting User Requests to Issues

When users describe problems or requests informally, structure them properly:

**User says:** "The thing doesn't work on my phone"

**Create issue:**
- Title: `App crashes on mobile devices`
- Type: `Bug`
- Labels: `needs info`
- Body: Request specific details (device, OS, steps to reproduce)

**User says:** "Can we add a feature to export data?"

**Create issue:**
- Title: `Add data export functionality`
- Type: `Feature`
- Body: Ask for format preferences (CSV, JSON), use cases, specific fields needed

### Linking Related Work

When creating issues related to other work:

```markdown
Related to #123
Depends on #456
Blocks #789
Duplicate of #012
```

Use GitHub's auto-linking by referencing issue numbers with `#`.

## Converting Task Documents to Issues

When converting structured task documents (like markdown backlogs) into GitHub issues:

### Hierarchy Mapping

Map document structure to GitHub's hierarchy:

| Document Level | GitHub Structure | Example |
|----------------|------------------|---------|
| H2 Section (`## Admin Dashboard`) | Epic or Milestone | "Admin Dashboard" epic |
| H3 Subsection (`### CRM`) | Parent Issue or Epic | "CRM Module" issue |
| H4 Category (`#### Pipeline`) | Issue | "Implement pipeline view" |
| Checkbox items (`- [ ] Task`) | Issue or subtask in body | Individual issues or checklist |

### Strategy: Epics with Linked Issues

For large backlogs, create a hierarchy:

1. **Create Epic issues** for major sections (H2/H3 levels)
2. **Create child issues** for individual tasks
3. **Link children to parent** using "Part of #epic-number" in the body
4. **Use task lists in epics** to track progress:

```markdown
## Epic: CRM Module

Implement all CRM functionality including leads, pipeline, and customer management.

### Tasks
- [ ] #123 Improve pipeline UI/UX
- [ ] #124 Add search and filters to leads
- [ ] #125 Validate kanban settings
```

### Bulk Issue Creation Workflow

When converting a task document:

1. **Analyze structure** - Identify sections, subsections, and individual tasks
2. **Define labels** - Create area labels matching document sections
3. **Create epics first** - Start with top-level sections
4. **Create child issues** - Reference parent epic in each
5. **Update epic with links** - Edit epic body to include issue references

Example for a section like:
```markdown
### CRM
#### Pipeline
- [ ] Improve UI/UX
- [ ] Validate settings work properly
```

Creates:
- Epic: "CRM Module" with label `area:crm`
- Issue: "Improve pipeline UI/UX" with labels `area:crm`, `ui/ux`, linked to epic
- Issue: "Validate pipeline settings" with labels `area:crm`, `settings`, linked to epic

### Area Labels for Projects

Define area labels matching your project structure:

```bash
# Create area labels
gh label create "area:dashboard" --color "0052CC" --description "Dashboard and analytics"
gh label create "area:inventory" --color "0052CC" --description "Inventory management"
gh label create "area:crm" --color "0052CC" --description "CRM and leads"
gh label create "area:platform" --color "0052CC" --description "Platform pages and layout"
gh label create "area:settings" --color "0052CC" --description "Settings and configuration"
gh label create "area:user-profile" --color "0052CC" --description "User profile features"
gh label create "area:integrations" --color "0052CC" --description "Third-party integrations"
```

### Title Transformations for Tasks

Convert informal task descriptions to proper issue titles:

| Original Task | Issue Title |
|---------------|-------------|
| "Get the charts and data the customers want" | "Define dashboard chart requirements" |
| "Add custom date range to the page" | "Add custom date range picker to analysis page" |
| "Improve UI/UX" | "Improve pipeline page UI/UX" |
| "Validate settings work properly" | "Validate pipeline settings functionality" |
| "Support also in project that are fully for rent" | "Add support for rental-only projects" |

### Nested Tasks

For tasks with sub-items, either:

**Option A: Single issue with checklist**
```markdown
## Add project type support

Support different project types in the system.

### Subtasks
- [ ] For rent projects
- [ ] Government projects (Mehir Lamishtaken)
- [ ] Urban renewal projects
```

**Option B: Parent issue with linked child issues**
- Parent: "Add project type support"
- Children: "Support rental projects", "Support government projects", "Support urban renewal projects"

Choose based on complexity - use checklists for simple related items, linked issues for complex features needing separate tracking.
