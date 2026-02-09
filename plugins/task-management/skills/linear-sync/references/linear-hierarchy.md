# Linear – Concepts, Hierarchy, and Features

This document summarizes Linear's main entities, hierarchy, and core features in a way that is useful for modeling or implementation.

---

## 1. Conceptual model & hierarchy

### 1.1 High‑level hierarchy

From top to bottom, the main hierarchy looks like:

- Workspace → Teams → (Sub‑teams) → (Initiatives) → Projects → Milestones → Issues → Sub‑issues.

Timeboxing cuts across this:

- Cycles are **team‑level** timeboxes that sit alongside projects and milestones, not above or below them.

### 1.2 Core concepts

- Workspace: Organization‑level container for all teams, issues, projects, and configuration.
- Team: Primary unit of ownership; issues belong to exactly one team, and cycles are defined per team.
- Sub‑team: Optional layer to mirror org structure under a team (e.g. "Platform", "Growth" within "Engineering").
- Initiative: Strategic grouping of projects by company objective; used in planning and roadmapping.
- Project: Collection of related issues, often cross‑team, with its own status, lead, and timeline.
- Milestone: Stage or checkpoint within a project with progress based on attached issues.
- Issue: Atomic unit of work; must have a title and status, everything else is optional.
- Sub‑issue: Nested task under a parent issue; can belong to different teams than the parent.
- Cycle: Team‑level timebox (sprint) containing a subset of that team's issues.

---

## 2. Entities and their properties

### 2.1 Workspace

- Holds:
  - Teams, sub‑teams, projects, issues, cycles, views, automations, and integrations.
- Key aspects:
  - Single recommended workspace per company.
  - Global settings: SSO/security (by plan), default views, integrations, and workspace‑wide configuration.

### 2.2 Teams and sub‑teams

- Team properties:
  - Name and key (used for issue IDs), workflow (statuses), estimate scale, default cycle configuration, and permissions.
- Responsibilities:
  - Owns backlog, "Active" and "All" issue views, cycles, and often projects.
- Sub‑teams:
  - Used to mirror org structure, aggregate work at higher levels, and manage across sub‑groups.

### 2.3 Initiatives

- Role:
  - Group projects by company objectives or themes for alignment and tracking.
- Properties:
  - Name, description, owner, associated projects, and roadmap/timeline position.
- Behavior:
  - Show project status and milestone progress within the initiative view; filter by next/completed milestones.

### 2.4 Projects

- Purpose:
  - Mid‑layer container for work; can be attached to one or several teams.
- Properties:
  - Status (e.g. Planned, In Progress, Completed), lead, members, description, start/target dates, teams, initiatives, milestones.
- Views:
  - Project overview (description + milestones + key issues), project issues list/board, project timeline.

### 2.5 Milestones

- Purpose:
  - Divide projects into phases like Design, Build, Launch, each with their own progress.
- Properties:
  - Name, target date (optional), description, completion percentage (based on completed issues in that milestone).
- Behavior:
  - Filter/group project issues by milestone.
  - Visible on project and initiative timelines as diamond markers with color changes based on completion.

### 2.6 Issues and sub‑issues

- Required properties:
  - Title and status.
- Optional properties:
  - Priority, estimate, labels, assignee, due date, project, milestone, cycle, customer, relations (blocked, blocking, related, duplicate), attachments, links (PRs/commits, Sentry, etc.).
- Relations:
  - Sub‑issues allow nested work; relations model dependencies and duplicates.

---

## 3. Views, filters, and display

### 3.1 Views

- Definition:
  - Saved queries (filters + display settings) that dynamically show matching issues.
- Built‑in:
  - Backlog, All, Active for teams; My Issues; Inbox for notifications.
- Scope:
  - Views can be private, team‑visible, or workspace‑visible.

### 3.2 Display options

- Per‑view controls:
  - Layout: List or board.
  - Grouping: Status, assignee, label, project, milestone, cycle, or none (depending on view).
  - Sorting: Priority, created/updated at, due date, status, etc.
  - Columns/fields:
    - ID, priority, status, labels, project, cycle, assignee, estimate, due date, created/updated time, time in status, linked Sentry issues, connected PRs/commits, SLA (higher plans).

### 3.3 Filtering and search

- Filters:
  - By assignee, label, status, priority, cycle, project, milestone, team, date ranges, and more.
- Global search:
  - Command‑palette‑like search across issues, projects, teams, and views.

---

## 4. Workflow and timeboxing

### 4.1 Workflows and statuses

- Team workflows:
  - Each team defines its own set of statuses and transitions.
- Status behavior:
  - Status groups such as Backlog, In Progress, Completed; status drives reporting and time‑in‑status metrics.

### 4.2 Cycles

- Purpose:
  - Timeboxed sprints to scope and commit work per team.
- Properties:
  - Start date, duration, recurring schedule, auto‑add rules, and auto‑rollover of incomplete issues.
- Views:
  - Cycle issues in list/board format, cycle burndown and progress via Insights.

---

## 5. Collaboration and communication features

### 5.1 Comments and notifications

- Comments:
  - Threaded discussions on issues with mentions and file links.
- Mentions and following:
  - @‑mentions, followers list per issue, and follow/unfollow actions.
- Inbox:
  - Central feed of updates on issues you follow or own.

### 5.2 Project and initiative communication

- Project update pages:
  - Narrative descriptions, status updates, and curated issue lists per project.
- Initiative views:
  - Show project tiles with status, progress, and current milestone; filters for upcoming/completed milestones.

---

## 6. Planning, analytics, and insights

### 6.1 Roadmap & timeline

- Roadmap:
  - Timeline view of projects and initiatives across teams, including milestones and dependencies.
- Dependencies:
  - Model project‑to‑project dependencies and see them visually on the timeline.
- Timeline extras:
  - Chronology bar, overlapping cycles, keyboard commands for navigation.

### 6.2 Insights

- Dashboards:
  - Configurable dashboards of charts over issues, projects, cycles, and teams.
- Metrics:
  - Throughput, cycle time, time in status, work‑in‑progress, completion trends, etc.
- Controls:
  - Group/slice by assignee, label, status, team, project, date ranges; multiple chart types per dashboard.

---

## 7. AI features

- AI summaries:
  - Summarize long issue threads and context for faster onboarding.
- AI prioritization:
  - Assist with ordering backlog items based on signals.
- AI reports:
  - Generate cycle and project reports automatically.
- AI workflows/agents:
  - Automate repetitive operations and product dev workflows.

---

## 8. Templates, automation, and integrations

### 8.1 Issue templates and forms

- Templates:
  - Pre‑defined structures for issues, including default properties like team, status, priority, assignee, project, labels, sub‑issues.
- Property form fields:
  - Customer, label group, priority, title, due date as explicit fields rather than only description text.

### 8.2 Automation

- Built‑in automations:
  - Auto‑close stale issues, move on state change, add to cycle, or set properties based on triggers.
- External automation:
  - Zapier/Make connections for cross‑tool workflows.

### 8.3 Integrations

- GitHub:
  - Link branches, PRs, commits; transition issue status on merge.
- Slack:
  - Notifications, unfurls, and quick actions from messages.
- Design/dev/security tools:
  - Figma, Loom, Sentry, Snyk, and others embedded or linked to issues.
- Time/scheduling:
  - Tools like Everhour and Morgen integrating for time tracking and calendar‑driven workflows.

---

## 9. UX, performance, and platform

- Web app:
  - High‑performance SPA, sub‑100ms feel, optimistic updates.
- Real‑time sync:
  - Low‑latency collaboration across clients.
- Keyboard‑first:
  - Global "C" to create issues, "Cmd/Ctrl+K" for the command menu, and rich keyboard shortcuts.
- Mobile:
  - Mobile apps to manage issues, projects, and notifications.

---

## 10. Security, plans, and admin

- Security:
  - SSO and enterprise security features depending on plan.
- Plan‑gated features:
  - Some SLA and analytics capabilities restricted to Business/Enterprise tiers.
- Administration:
  - Manage teams, sub‑teams, permissions, workflows, and workspace‑wide integrations from admin settings.

---

## 11. Relationship summary

- Workspace:
  - Has many teams, projects, issues, views, cycles, and settings.
- Team:
  - Has many issues and cycles; may have many projects and sub‑teams.
- Initiative:
  - Has many projects.
- Project:
  - Has many issues and milestones; may belong to multiple teams and one or more initiatives.
- Milestone:
  - Has many issues; belongs to exactly one project.
- Issue:
  - Belongs to one team; optionally to one project, one milestone, one cycle, one parent issue; may have many sub‑issues and relations.
- Cycle:
  - Belongs to one team; has many issues.
