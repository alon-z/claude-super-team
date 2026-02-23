# Feedback Collection Procedure

**The goal of this step is to fully understand what the user wants changed before planning anything.** Vague feedback leads to wrong plans. Use AskUserQuestion iteratively until you have concrete, actionable feedback.

**4a. Initial feedback collection:**

If `$ARGUMENTS` contains feedback text (beyond the phase number), use it as the starting point -- but still proceed to 4b to clarify.

If no feedback in arguments, use AskUserQuestion:

```
AskUserQuestion:
  header: "Feedback"
  question: "What would you like to change about Phase {N}'s output?"
  options:
    - "Visual/Design" -- "Change how something looks (layout, styling, colors)"
    - "Behavior" -- "Change how something works (interactions, logic, flow)"
    - "Missing feature" -- "Add something that was left out"
    - "Quality" -- "Fix bugs, improve performance, or harden"
```

**4b. Drill down into specifics:**

After receiving the initial feedback (from args or the question above), ask targeted follow-ups to remove ambiguity. Use AskUserQuestion for each area that needs clarification. Examples:

- If "visual/design": "Which part of the UI needs to change?" with options listing specific components/pages from the parent phase summaries
- If "behavior": "What should happen differently?" with options describing current vs desired behavior
- If "missing feature": "What specifically is missing?" with options based on what was NOT built in the parent phase
- If feedback mentions a specific page/component: "How should {component} look/work instead?" with concrete alternatives

**4c. Confirm understanding:**

Summarize the collected feedback back to the user and confirm with AskUserQuestion:

```
AskUserQuestion:
  header: "Confirm"
  question: "Here's what I understand you want changed:\n\n{bullet list of specific changes}\n\nIs this accurate?"
  options:
    - "Yes, proceed" -- "This captures my feedback correctly"
    - "Not quite" -- "I want to clarify or add something"
```

If "Not quite," loop back to 4b and ask what needs adjusting.

**4d. Store final feedback:**

Only after confirmation, store as `$FEEDBACK`. This should be a concrete, specific description -- not a vague wish. Good: "Change the marketplace grid from 2 columns to 3 columns, add plugin icons to each card, and make the search bar full-width." Bad: "Make the marketplace look better."
