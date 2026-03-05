---
name: addictive-apps-design
description: Emotional design principles for building apps people love and return to. Covers micro-interactions, feedback loops, trust-building motion, and premium feel. Use when designing or reviewing user flows, UI components, onboarding, progress systems, or feedback mechanisms -- or when the user wants an engagement audit of existing implementation.
allowed-tools: Read, Glob, Grep, Edit, Write, AskUserQuestion, mcp__pencil__get_editor_state, mcp__pencil__batch_get, mcp__pencil__snapshot_layout, mcp__pencil__get_screenshot, mcp__pencil__get_variables, mcp__pencil__search_all_unique_properties
---

# Addictive Apps Design

Emotional design is the practice of making products feel engaging, personal, and alive. In a market where every team has access to the same stack, the edge is how your product makes people feel when they open it.

> "The product has to be so good people want to talk about it." -- Reed Hastings, Netflix co-founder

Foundational theory: Don Norman, *Emotional Design* -- emotional feedback loops are the mechanism behind habit-forming UX.

## How to Use This Skill

**Designing something new**: Apply the three patterns below as you design each flow or component. The review checklist at the bottom doubles as a design checklist.

**Reviewing existing implementation**: Read the relevant code and/or design files, then run the checklist against what exists. Produce a prioritized list of improvements with specific, implementable suggestions.

**Reviewing .pen design files**: When the product has Pencil design files (.pen), use them as the primary review surface -- they show the actual design intent more clearly than code. Workflow:
1. `get_editor_state` -- check if a .pen file is already open
2. `batch_get` -- search for screens, components, and flows (e.g., onboarding, success states, error states, progress indicators)
3. `get_screenshot` -- visually inspect key screens against the checklist
4. `snapshot_layout` -- check spacing, hierarchy, and structure
5. `get_variables` -- audit design tokens and theme consistency
6. `search_all_unique_properties` -- scan for animation/transition properties, interaction states, and motion definitions across the entire design

This works for both web and mobile designs. Ask the user which .pen files to review if multiple exist.

**Unclear context**: Use `AskUserQuestion` to ask: what is the product, who is the user, and what's the core repeated action? This determines which pattern is most relevant.

For detailed case studies with data, quotes, and full tactical breakdowns, read `${CLAUDE_SKILL_DIR}/references/case-studies.md`.

---

## Pattern 1: Emotional Feedback Loops

**When to apply**: Products that rely on repeated user behavior -- check-ins, habit logging, learning, journaling, streaks.

The key insight: users shouldn't just *see* a result, they should *feel* it. A green checkmark is functional. A bouncing character that cheers you on is emotional.

**Tactics:**
- Add micro-interactions on confirmation moments: subtle bounce, glow, sparkle. Small signals that the action *mattered*.
- Celebrate small wins. Success states don't need to be big -- they need to feel *intentional*.
- If the product has a mascot or character, use expressions to encourage: nods, smiles, reactions. Emotions are contagious.
- Use progress animations to create momentum: streaks, level indicators, completion counts -- anything that creates a sense of *building something over time*.
- Make feedback feel human, not transactional. The emotional layer quietly builds attachment between user and product.

---

## Pattern 2: Trust Through Polish

**When to apply**: Intimidating, complex, or high-stakes domains -- finance, crypto, health, insurance, legal. Also: early-stage products trying to win over skeptical users.

The key insight: in spaces where users are scared or unsure, every visual detail is a trust signal. Polish *is* the product for your first-time users.

**Tactics:**
- Treat motion, transitions, and visual details as *core product features*, not polish added later. Every micro-interaction either builds or erodes trust.
- Friendly visuals and warm, playful details make heavy topics feel lighter. Approachability reduces friction.
- Design for everyday people, not just power users or early adopters. Don't assume users know the vocabulary of your domain.
- What sticks is how the product *feels* when someone taps, swipes, or waits. Smooth, responsive feedback increases confidence even when nothing has changed functionally.

---

## Pattern 3: Premium Feel

**When to apply**: Products moving upmarket, consumer fintech, anything where the brand promise is quality or exclusivity. Also relevant any time onboarding is the first impression.

The key insight: premium isn't about price -- it's about how the product feels in your hands. Tactile interactions and rich motion communicate quality before the user consciously processes anything.

**Tactics:**
- Nail the first impression. Polish onboarding and welcome moments to immediately communicate quality, trust, and care. This is the moment that sets the frame for the entire relationship.
- Add subtle moments of delight: animations, fades, hover effects, gesture responses. Touch points should feel *intentional*, not accidental.
- Make interactions feel dynamic and tactile: responsive charts, cards that flip and catch light, transitions that have weight. These turn basic features into experiences that feel elevated.
- Don't shout. None of these details should call attention to themselves. Together, they should create an ambient sense of quality.

---

## Review Checklist

Run this against any existing implementation to find gaps. For each item, note: present / missing / improvable.

**Feedback & Reactions**
- [ ] Confirmation moments have emotional feedback (not just a checkmark or toast)
- [ ] Errors feel corrective, not punishing -- tone and motion are considered
- [ ] Small wins are acknowledged with intentional success states
- [ ] Progress is visualized (streaks, counts, levels, completion bars)

**Motion & Micro-interactions**
- [ ] Transitions between screens/states have appropriate easing and duration
- [ ] Interactive elements (buttons, toggles, sliders) have tactile response on press
- [ ] Loading/waiting states have motion that signals life, not just a spinner
- [ ] Key moments (onboarding completion, first success, milestones) have a special animation

**Trust Signals**
- [ ] Onboarding flow communicates quality and care from the first screen
- [ ] Security or sensitive flows (permissions, payments) have reassuring visual treatment
- [ ] Copy and visual tone are appropriate for the anxiety level of the domain
- [ ] The product works for a first-time, non-expert user without guidance

**Character & Personality**
- [ ] The product has a consistent visual personality (it doesn't feel generic)
- [ ] If there's a mascot or character, it reacts to user actions meaningfully
- [ ] Delight moments feel surprising but inevitable -- not random

**Premium Indicators**
- [ ] First-time experience (onboarding, empty states) is polished, not placeholder-quality
- [ ] Charts, data displays, or key features feel dynamic and responsive
- [ ] The product would be remarked on positively by someone who just used it for the first time
