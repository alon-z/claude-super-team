# Quick Fix Application Flow

This path is for trivial changes: single-file tweaks, typos, small style or logic fixes. No subphase, no plan, no agent spawning.

**6a. Locate target files.** Read the target file(s) mentioned in the feedback. Use the execution context from Step 3 to locate exact file paths.

**6b. Apply changes.** Apply the change directly using Edit/Write tools. Keep the change minimal and focused on exactly what the feedback requested.

**6c. Verify changes.** Verify the change works (run relevant commands if applicable).

**6d. Present completion summary:**

```
Quick fix applied for Phase ${PARENT_PHASE}.

Feedback: ${FEEDBACK}
Files changed: {list of files modified}

---

## Next Steps

**More feedback?**
  /phase-feedback ${PARENT_PHASE}

**Continue to next phase:**
  /progress to see what's next

**Commit if desired:**
  git add {changed files} && git commit -m "fix: {short description of fix}"

---
```

Never auto-commit. **STOP here -- do not continue to Step 7.**
