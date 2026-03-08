---
phase: XX-name
plan: NN
type: execute
wave: N
depends_on: []
files_modified: []
autonomous: true

must_haves:
  truths: []
  artifacts: []
  key_links: []
---

<objective>
[What this plan accomplishes]

Purpose: [Why this matters for the project]
Output: [What artifacts will be created]
</objective>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: [Action-oriented name]</name>
  <files>path/to/file.ext</files>
  <action>[Specific implementation instructions]</action>
  <verify>[Command or check to confirm completion]</verify>
  <done>[Acceptance criteria - measurable state]</done>
</task>

</tasks>

<verification>
[Overall plan verification checks]
</verification>

<success_criteria>
[Measurable completion state]
</success_criteria>

<output>
After completion, create `.planning/phases/XX-name/{phase}-{plan}-SUMMARY.md`
</output>
