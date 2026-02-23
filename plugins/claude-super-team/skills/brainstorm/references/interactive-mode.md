# Interactive Brainstorming Procedure

### Phase 3: Define Topic

**If $ARGUMENTS provided:** Use as starting topic.

**If $ARGUMENTS empty:** Use AskUserQuestion:

- header: "Focus"
- question: "What would you like to brainstorm about?"
- multiSelect: false
- options:
  - label: "New feature"
    description: "Explore a feature to add to the project"
  - label: "Improvement"
    description: "Enhance existing functionality"
  - label: "Architecture"
    description: "Evaluate architectural changes"
  - label: "Open-ended"
    description: "Let's explore what's possible"

Follow up with 1-2 targeted questions to narrow focus. Generate options based on actual project context -- reference real modules, features, and constraints from the loaded context.

### Phase 4: Explore Ideas (Iterative)

**4.1. Generate 3-5 concrete ideas** based on topic, project context, and codebase constraints. Each idea: name, brief description, why it matters, key tradeoffs, complexity estimate.

**4.2. Present for selection** via AskUserQuestion (multiSelect: true). User picks which to explore.

**4.3. Deep-dive each selected idea.** Ask 3-4 targeted questions:
1. Scope -- "What should this include vs exclude?"
2. Tradeoffs -- "How do we balance X vs Y?"
3. Integration -- "How does this fit with existing work?"
4. Risk -- "What could go wrong?"

Use AskUserQuestion with concrete options. Always include a "You decide" option.

After questions, present a structured summary. Check if more refinement needed:

- header: "Refine"
- options: "Looks good" / "Needs tweaks" / "Pivot"

**4.4. Decision point** for each idea:

- header: "Decision"
- options: "Approve" / "Defer" / "Reject" / "Keep exploring"

**4.5. After all selected ideas processed:**

- header: "Continue"
- options: "More ideas" (return to 4.1) / "Different topic" (return to Phase 3) / "Wrap up" (continue to Phase 10)
