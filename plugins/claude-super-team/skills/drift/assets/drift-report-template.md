# Drift Report

**Generated:** {date}
**Phases analyzed:** {list}
**Scope:** {single phase N | all completed phases}

## Summary

| Category | Count |
|----------|-------|
| Confirmed Drift | {N} |
| Potential Drift | {N} |
| Aligned | {N} |
| Unverifiable | {N} |

## Findings

### Phase {N}: {Name}

#### Confirmed Drift

| # | Artifact | Claim | Actual State | Impact |
|---|----------|-------|--------------|--------|
| 1 | {source file} | {what artifact says} | {what codebase shows} | {high/medium/low} |

#### Potential Drift

| # | Artifact | Claim | Actual State | Why Unclear |
|---|----------|-------|--------------|-------------|
| 1 | {source file} | {what artifact says} | {what codebase shows} | {reason} |

#### Aligned

| # | Artifact | Claim | Verification |
|---|----------|-------|-------------|
| 1 | {source file} | {what artifact says} | {how confirmed} |

#### Unverifiable

| # | Artifact | Claim | Reason |
|---|----------|-------|--------|
| 1 | {source file} | {what artifact says} | {why unverifiable} |

{repeat per phase}

## Recommendations

{prioritized list of drift items to address, ordered by impact}
