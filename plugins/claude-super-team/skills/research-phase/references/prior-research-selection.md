# Prior Research Selection

Scan for RESEARCH.md files from other completed phases and select only those relevant to the current phase goal. This prevents re-researching topics already investigated while keeping context lean.

**Process:**

1. Use **PHASE_ARTIFACTS** from the gather script. For each phase directory where `research > 0` (excluding the current phase), note the phase name and directory.
2. For each prior RESEARCH.md, read only the first 20 lines (which contain the frontmatter and key findings summary).
3. Compare each prior phase's goal (from ROADMAP.md) against the current phase's goal. A prior research is **relevant** if:
   - It covers a domain the current phase touches (e.g., prior auth research is relevant to a login redesign phase)
   - It evaluated libraries/patterns the current phase will build on or modify
   - It contains architectural decisions that constrain the current phase
4. A prior research is **NOT relevant** if:
   - The prior phase covers an unrelated domain (e.g., payment research is irrelevant to a UI theming phase)
   - The prior phase's work is complete and the current phase neither extends nor modifies it

**Output:** Build a `prior_research` block containing only relevant entries. For each relevant prior RESEARCH.md, read the full file and include it. If no prior research is relevant, set `prior_research` to empty.

Expect 0-2 relevant files in most cases. If more than 3 are relevant, include only the top 3 most related to avoid bloating agent context.
