---
phase: NN.X-feedback-slug
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: []
autonomous: true
quick_phase: true
feedback_on: NN

must_haves:
  truths: []
  artifacts: []
  key_links: []
---

<objective>
[2-3 sentence description of the feedback-driven changes. State what the user wants changed and why.]

Feedback on Phase {NN}: [Summary of user's feedback]
Output: [Modified artifacts -- these should be existing files from the parent phase]
</objective>

<parent_context>
[Summary of what parent phase built -- key files, capabilities, architecture decisions.
This section is populated from SUMMARY.md and VERIFICATION.md of the parent phase.
The planner uses this to understand existing work that tasks will modify.]
</parent_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: [Modify-oriented name -- e.g., "Restyle marketplace card grid"]</name>
  <files>path/to/existing/file.ext</files>
  <action>[Specific modification instructions. Reference existing code/files from parent phase. Describe what to change, not what to build from scratch.]</action>
  <verify>[Automated check confirming the modification works]</verify>
  <done>[Clear acceptance criteria tied to the user's feedback]</done>
</task>

</tasks>

<verification>
[How to verify the feedback has been addressed -- should be checkable against user's original request]
</verification>

<success_criteria>
[Measurable completion state directly derived from user feedback]
</success_criteria>

<output>
After completion, create `.planning/phases/NN.X-feedback-slug/{phase}-01-SUMMARY.md`
</output>
