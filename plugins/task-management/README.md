# Task Management Plugin

Integrate task management workflows with Linear and GitHub for seamless project planning and issue tracking.

## Skills

- **linear-sync** (`/linear-sync`) - Sync `.planning/` artifacts to Linear for team tracking
- **github-issue-manager** (`/github-issue-manager`) - Create and maintain GitHub issues following best practices

## Quick Start

### Linear Sync

Sync your `.planning/` directory to Linear:

```bash
/linear-sync init                 # Initialize Linear connection
/linear-sync projects             # Sync roadmap phases to Linear projects
/linear-sync milestones           # Sync plan waves to Linear milestones
/linear-sync docs                 # Sync documentation files
/linear-sync issues [phase]       # Create/update issues from plans
/linear-sync status               # Show Linear sync state
```

### GitHub Issue Manager

Create and maintain GitHub issues with consistent standards:

```bash
/github-issue-manager             # Interactive issue creation and management
```

## Integration

Both skills work together to keep your planning, Linear workspace, and GitHub issues in sync across your development lifecycle.
