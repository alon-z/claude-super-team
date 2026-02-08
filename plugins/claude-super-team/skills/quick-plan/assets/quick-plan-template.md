---
phase: NN.X-name
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: []
autonomous: true
quick_phase: true

must_haves:
  truths: []
  artifacts: []
  key_links: []
---

<objective>
[2-3 sentence description of what this quick phase accomplishes]

Purpose: [Why this is being done now, outside the normal phase flow]
Output: [What artifacts will be created or modified]
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
  <action>[Specific implementation instructions - one paragraph max]</action>
  <verify>[Automated check - test command, curl, lint, etc.]</verify>
  <done>[Clear acceptance criteria]</done>
</task>

</tasks>

<verification>
[How to verify the entire quick phase is complete]
</verification>

<success_criteria>
[Measurable completion state - should match ROADMAP annotation's success criteria]
</success_criteria>

<output>
After completion, create `.planning/phases/NN.X-name/{phase}-01-SUMMARY.md`
</output>
