# Roadmap: TaskFlow

## Overview

TaskFlow is a collaborative task management mobile app built with React Native/Expo and a Node.js backend. The roadmap is organized into 9 phases across 3 sprints. Sprint 1 delivers a functional app where users can authenticate, create projects, invite team members, and manage tasks. Sprint 2 adds the kanban board with drag-and-drop, real-time collaboration via WebSocket, and search/filter with offline sync. Sprint 3 completes the experience with push notifications, a productivity dashboard, file attachments, and dark mode. Phases within each sprint run in parallel.

## Phases

- [ ] **Phase 1: Project Scaffolding & Design System** [Sprint 1] [S] - Expo + Node.js project setup, PostgreSQL schema, base theming
- [ ] **Phase 2: Authentication** [Sprint 1] [M] - Email/password and Google Sign-In with session management
- [ ] **Phase 3: Projects & Tasks Core** [Sprint 1] [M] - Project CRUD, team invitations, task CRUD with all fields
- [ ] **Phase 4: Kanban Board** [Sprint 2] [M] - Drag-and-drop kanban view with status columns
- [ ] **Phase 5: Real-Time Collaboration** [Sprint 2] [M] - WebSocket-based live updates across team members
- [ ] **Phase 6: Search, Filter & Offline Sync** [Sprint 2] [M] - Task search/filter and offline-first with background sync
- [ ] **Phase 7: Push Notifications & Deadline Alerts** [Sprint 3] [M] - Expo push notifications for 24h and 1h deadline reminders
- [ ] **Phase 8: Dashboard & Analytics** [Sprint 3] [M] - Productivity charts, overdue tracking, workload distribution
- [ ] **Phase 9: File Attachments & Dark Mode** [Sprint 3] [M] - Task file uploads via Cloudflare R2 and dark mode theme

## Phase Details

### Phase 1: Project Scaffolding & Design System
**Goal**: Establish the project foundation so all subsequent phases can build on a consistent codebase, database schema, and visual language.
**Sprint**: 1
**Size**: S
**Depends on**: Nothing (first phase)
**Requirements**: Foundation for all requirements; R10 (dark mode theming tokens)
**Success Criteria** (what must be TRUE when this phase completes):
  1. Running `npx expo start` launches the app on both iOS simulator and Android emulator with a welcome screen
  2. The Node.js backend starts and responds to a health-check endpoint
  3. PostgreSQL database is provisioned with initial migration for users, projects, and tasks tables
  4. A base theme (colors, typography, spacing) is defined and applied to the welcome screen

### Phase 2: Authentication
**Goal**: Users can create accounts and sign in so they have a persistent, secure identity within the app.
**Sprint**: 1
**Size**: M
**Depends on**: Phase 1
**Requirements**: R1
**Success Criteria** (what must be TRUE when this phase completes):
  1. A new user can register with email and password, then log in and see a home screen
  2. A user can sign in with Google Sign-In and land on the same home screen
  3. Sessions persist across app restarts -- closing and reopening the app does not require re-login
  4. Invalid credentials show clear error messages without crashing

### Phase 3: Projects & Tasks Core
**Goal**: Authenticated users can create projects, invite teammates, and manage tasks with all required fields -- delivering the core data loop of the app.
**Sprint**: 1
**Size**: M
**Depends on**: Phase 2
**Requirements**: R2, R3
**Success Criteria** (what must be TRUE when this phase completes):
  1. A user can create a project, give it a name, and see it listed on their home screen
  2. A user can invite team members to a project by email, and invited users see the project after accepting
  3. Within a project, a user can create a task with title, description, deadline, priority (P1-P4), assignee, and status (todo/in-progress/done)
  4. Tasks can be edited and deleted, and changes persist after app restart
  5. A project shows its task list with priority and status visible at a glance

### Phase 4: Kanban Board
**Goal**: Users can visualize and reorganize their tasks through an intuitive drag-and-drop kanban interface grouped by status.
**Sprint**: 2
**Size**: M
**Depends on**: Phase 3
**Requirements**: R4
**Success Criteria** (what must be TRUE when this phase completes):
  1. A project displays tasks in three columns: Todo, In Progress, and Done
  2. A user can drag a task from one column to another, and the task's status updates accordingly
  3. The kanban board reflects the current state of all tasks in the project without requiring a manual refresh
  4. Drag-and-drop works smoothly on both iOS and Android with visual feedback during the drag

### Phase 5: Real-Time Collaboration
**Goal**: When any team member changes a task, all other online members see the update instantly -- making the app feel truly collaborative.
**Sprint**: 2
**Size**: M
**Depends on**: Phase 3
**Requirements**: R5
**Success Criteria** (what must be TRUE when this phase completes):
  1. When User A moves a task to "Done," User B sees the task move on their screen within 2 seconds without refreshing
  2. When User A creates a new task, it appears on User B's task list and kanban board in real time
  3. The WebSocket connection reconnects automatically after a brief network interruption
  4. Redis pub/sub distributes updates so the system works across multiple backend instances

### Phase 6: Search, Filter & Offline Sync
**Goal**: Users can quickly find tasks and continue working without an internet connection, with changes syncing automatically when connectivity returns.
**Sprint**: 2
**Size**: M
**Depends on**: Phase 3
**Requirements**: R8, offline constraint
**Success Criteria** (what must be TRUE when this phase completes):
  1. A user can search tasks by title and see matching results as they type
  2. A user can filter tasks by assignee, priority, deadline range, and status -- filters combine correctly
  3. With airplane mode on, a user can view existing tasks and create new tasks without errors
  4. After reconnecting, offline changes sync to the server and appear for other team members

### Phase 7: Push Notifications & Deadline Alerts
**Goal**: Users receive timely reminders about approaching deadlines so tasks don't slip through the cracks.
**Sprint**: 3
**Size**: M
**Depends on**: Phase 3
**Requirements**: R6
**Success Criteria** (what must be TRUE when this phase completes):
  1. A user receives a push notification 24 hours before a task deadline
  2. A user receives a push notification 1 hour before a task deadline
  3. Notifications appear even when the app is in the background or closed
  4. Tapping a notification opens the app directly to the relevant task

### Phase 8: Dashboard & Analytics
**Goal**: Project owners and team leads can see productivity trends and workload distribution to make informed decisions.
**Sprint**: 3
**Size**: M
**Depends on**: Phase 3
**Requirements**: R7
**Success Criteria** (what must be TRUE when this phase completes):
  1. A dashboard screen shows a bar chart of tasks completed per week for the past 4 weeks
  2. Overdue tasks are highlighted with a count and a list view accessible from the dashboard
  3. A workload distribution chart shows how many tasks are assigned to each team member
  4. Charts update to reflect current data each time the dashboard is opened

### Phase 9: File Attachments & Dark Mode
**Goal**: Users can attach reference files to tasks and switch to a dark theme for comfortable use in any lighting condition.
**Sprint**: 3
**Size**: M
**Depends on**: Phase 3 (attachments), Phase 1 (dark mode theming)
**Requirements**: R9, R10
**Success Criteria** (what must be TRUE when this phase completes):
  1. A user can attach images and PDFs (up to 10MB) to a task, and attachments display inline or as downloadable links
  2. Uploaded files are stored in Cloudflare R2 and remain accessible after app restart
  3. A user can toggle dark mode from settings, and the entire app switches to a dark color scheme
  4. Dark mode preference persists across app restarts

## Sprint Summary

| Sprint | Phases | What's Demoable After |
|--------|--------|-----------------------|
| 1 | Phase 1, Phase 2, Phase 3 | User can sign up, create a project, invite teammates, and manage tasks with priorities and deadlines |
| 2 | Phase 4, Phase 5, Phase 6 | Kanban board with drag-and-drop, real-time updates across users, search/filter, and offline mode |
| 3 | Phase 7, Phase 8, Phase 9 | Push notification reminders, productivity dashboard with charts, file attachments, and dark mode |

## Progress

| Phase | Sprint | Size | Status | Completed |
|-------|--------|------|--------|-----------|
| 1. Project Scaffolding & Design System | 1 | S | Not started | - |
| 2. Authentication | 1 | M | Not started | - |
| 3. Projects & Tasks Core | 1 | M | Not started | - |
| 4. Kanban Board | 2 | M | Not started | - |
| 5. Real-Time Collaboration | 2 | M | Not started | - |
| 6. Search, Filter & Offline Sync | 2 | M | Not started | - |
| 7. Push Notifications & Deadline Alerts | 3 | M | Not started | - |
| 8. Dashboard & Analytics | 3 | M | Not started | - |
| 9. File Attachments & Dark Mode | 3 | M | Not started | - |

---
*Created: 2026-03-05*
