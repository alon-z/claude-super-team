# Project: TaskFlow

## Vision
A collaborative task management mobile app (React Native + Expo) with a Node.js backend. Users create projects, add tasks with deadlines and priorities, assign tasks to team members, and track progress through kanban boards. Features real-time updates via WebSocket, push notifications for deadlines, and a dashboard with productivity analytics.

## Core Value
Teams can manage their work in one place with real-time collaboration and actionable insights.

## Requirements

### Active
- R1: User authentication (email/password + Google Sign-In)
- R2: Project CRUD with team member invitations
- R3: Task CRUD with title, description, deadline, priority (P1-P4), assignee, status (todo/in-progress/done)
- R4: Kanban board view with drag-and-drop between columns
- R5: Real-time updates -- when one user moves a task, all team members see it instantly
- R6: Push notifications for approaching deadlines (24h, 1h before)
- R7: Dashboard with charts: tasks completed per week, overdue tasks, team workload distribution
- R8: Search and filter tasks by assignee, priority, deadline, status
- R9: File attachments on tasks (images, PDFs, up to 10MB)
- R10: Dark mode support

## Constraints
- React Native with Expo (managed workflow)
- Backend: Node.js with Express or Hono
- Database: PostgreSQL
- Must work offline with sync when reconnected
- Target: iOS and Android

## Key Decisions
- Using Expo managed workflow (no native modules requiring ejection)
- PostgreSQL for relational data, Redis for real-time pub/sub
- Cloudflare R2 for file storage
