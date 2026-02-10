> **Note:** The authoritative version of this content is embedded in
> `agents/phase-researcher.md`. This file is kept as standalone reference.
> Edit the agent file for runtime changes.

# Research for Phase {phase_number}: {phase_name}

## User Constraints

{Verbatim from CONTEXT.md locked decisions, discretion areas, and deferred items. If no CONTEXT.md exists, note: "No CONTEXT.md -- no locked decisions."}

---

## Summary

{Executive summary of research findings. Primary recommendation in 2-3 sentences. Overall confidence level: HIGH / MEDIUM / LOW.}

---

## Standard Stack

### Core Libraries

| Library | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| {name} | {version} | {what it does} | {HIGH/MEDIUM/LOW} |

### Supporting Libraries

| Library | Version | Purpose | Confidence |
|---------|---------|---------|------------|
| {name} | {version} | {what it does} | {HIGH/MEDIUM/LOW} |

### Alternatives Considered

| Alternative | Why Not |
|-------------|---------|
| {name} | {reason rejected} |

---

## Architecture Patterns

### Project Structure

```
{recommended directory/file layout}
```

### Design Patterns

- **{Pattern name}**: {When and how to apply it}

### Anti-Patterns

- **{Anti-pattern name}**: {Why to avoid it, what to do instead}

---

## Don't Hand-Roll

{Problems with well-established solutions -- use libraries, don't build custom.}

| Problem | Solution | Why Not Custom |
|---------|----------|----------------|
| {problem} | {library/approach} | {reason} |

---

## Common Pitfalls

| Pitfall | Impact | How to Avoid |
|---------|--------|--------------|
| {what goes wrong} | {consequences} | {prevention strategy} |

---

## Code Examples

{Verified patterns from official sources. Include source URL.}

### {Example Name}

```{language}
{code}
```

Source: {URL}

---

## State of the Art

| Aspect | Old Approach | Current Approach | What Changed |
|--------|-------------|-----------------|--------------|
| {aspect} | {old} | {current} | {why it changed} |

---

## Open Questions

{Gaps in research, items needing validation, areas where sources conflict.}

- {question}: {context and why it matters}

---

## Sources

| Source | Type | Confidence | URL |
|--------|------|------------|-----|
| {name} | {official docs / blog / repo / forum} | {HIGH/MEDIUM/LOW} | {url} |

---

## Metadata

- **Research date:** {date}
- **Phase:** {phase_number} - {phase_name}
- **Confidence breakdown:** {N} HIGH, {N} MEDIUM, {N} LOW findings
- **Firecrawl available:** {yes/no}
- **Sources consulted:** {count}
