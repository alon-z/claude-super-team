# Roadmap: TaskFlow

## Overview

TaskFlow is a collaborative task management mobile app built with React Native (Expo) and a Node.js backend. The roadmap moves from authentication and core data foundations through task management and real-time collaboration, culminating in notifications, file handling, and productivity analytics. Each phase delivers a complete, usable capability that builds on the previous one, with offline sync woven into the real-time phase to honor the constraint that the app must work without connectivity.

## Phases

- [ ] **Phase 1: Foundation & Authentication** - Backend scaffolding, database setup, and user auth with email/password and Google Sign-In
- [ ] **Phase 2: Projects & Teams** - Project CRUD with team member invitations and role structure
- [ ] **Phase 3: Task Management & Board** - Task CRUD, kanban board with drag-and-drop, and search/filter capabilities
- [ ] **Phase 4: Real-Time Collaboration & Offline Sync** - WebSocket-driven live updates and offline-first data sync
- [ ] **Phase 5: Notifications & File Attachments** - Push notifications for deadlines and file attachment support on tasks
- [ ] **Phase 6: Analytics & Polish** - Productivity dashboard with charts and dark mode support

## Phase Details

### Phase 1: Foundation & Authentication
**Goal**: Users can create accounts and sign in securely, establishing the identity layer that every subsequent feature depends on.
**Depends on**: Nothing (first phase)
**Requirements**: R1 (User authentication -- email/password + Google Sign-In)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A user can register with email and password, then log in and receive a persistent session
  2. A user can sign in with Google and land on an authenticated home screen
  3. An unauthenticated request to any protected API endpoint returns a 401 and the mobile app redirects to the sign-in screen
  4. The backend is running with Express or Hono connected to PostgreSQL, and the React Native Expo app builds for both iOS and Android

### Phase 2: Projects & Teams
**Goal**: Authenticated users can create projects and invite team members, forming the organizational containers for all task work.
**Depends on**: Phase 1
**Requirements**: R2 (Project CRUD with team member invitations)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A user can create, view, edit, and delete projects from the mobile app
  2. A project owner can invite other users by email and those users see the project in their project list after accepting
  3. A user who is not a member of a project cannot see or access that project's data

### Phase 3: Task Management & Board
**Goal**: Team members can create and manage tasks within projects, visualize work on a kanban board, and find tasks through search and filters.
**Depends on**: Phase 2
**Requirements**: R3 (Task CRUD with title, description, deadline, priority, assignee, status), R4 (Kanban board with drag-and-drop), R8 (Search and filter tasks)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A user can create a task with title, description, deadline, priority (P1-P4), and assignee, then edit or delete it
  2. Tasks appear on a kanban board with columns for todo, in-progress, and done, and a user can drag a task between columns to change its status
  3. A user can search tasks by keyword and filter the task list by assignee, priority, deadline range, or status
  4. Task state changes made through the kanban board are persisted and visible after app restart

### Phase 4: Real-Time Collaboration & Offline Sync
**Goal**: Multiple team members see each other's changes instantly, and the app remains functional without network connectivity by syncing when reconnected.
**Depends on**: Phase 3
**Requirements**: R5 (Real-time updates -- task moves visible instantly to all team members)
**Success Criteria** (what must be TRUE when this phase completes):
  1. When one user moves a task on the kanban board, another user viewing the same project sees the change appear within seconds without refreshing
  2. A user can create and edit tasks while offline, and those changes sync to the server and other clients when connectivity is restored
  3. Conflicting offline edits from two users are resolved without data loss (last-write-wins or merge strategy is visible to the user)

### Phase 5: Notifications & File Attachments
**Goal**: Users receive timely reminders about approaching deadlines and can attach files to tasks for richer context.
**Depends on**: Phase 4
**Requirements**: R6 (Push notifications for approaching deadlines -- 24h and 1h before), R9 (File attachments on tasks -- images, PDFs, up to 10MB)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A user with a task due tomorrow receives a push notification 24 hours before the deadline and another 1 hour before
  2. A user can attach an image or PDF (up to 10MB) to a task and other team members can view or download that attachment
  3. Push notifications arrive on both iOS and Android devices even when the app is in the background

### Phase 6: Analytics & Polish
**Goal**: Project leads can view productivity insights through a dashboard, and all users benefit from dark mode for comfortable use in any lighting.
**Depends on**: Phase 5
**Requirements**: R7 (Dashboard with charts -- tasks completed per week, overdue tasks, team workload distribution), R10 (Dark mode support)
**Success Criteria** (what must be TRUE when this phase completes):
  1. A user can open the dashboard and see a chart of tasks completed per week over the last 4+ weeks
  2. The dashboard shows a count of currently overdue tasks and a visualization of workload distribution across team members
  3. A user can toggle dark mode in settings and all screens render with a dark color scheme that is readable and consistent

## Progress

| Phase | Status | Completed |
|-------|--------|-----------|
| 1. Foundation & Authentication | Not started | - |
| 2. Projects & Teams | Not started | - |
| 3. Task Management & Board | Not started | - |
| 4. Real-Time Collaboration & Offline Sync | Not started | - |
| 5. Notifications & File Attachments | Not started | - |
| 6. Analytics & Polish | Not started | - |

---
*Created: 2026-03-05*
