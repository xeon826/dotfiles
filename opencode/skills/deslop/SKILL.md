---
name: deslop
description: |
  Remove the AI-generated look ("AI slop") from frontend code and designs.
  Use when a website, landing page, or web app looks AI-generated or
  template-made, when the user asks to de-slop/deslop a frontend, or when
  auditing a UI for AI design tells: purple-blue gradients, Inter
  typography, repeated 3-column card grids, buzzword copy, emoji icons,
  scroll-reveal on everything. Provides a 30-check audit scorecard and
  concrete fixes. Based on the aitoolpick.org 30-point AI-generated
  website checklist.
license: MIT
metadata:
  version: "1.0.0"
  source: https://aitoolpick.org/blog/ai-generated-website-checklist/
---

# Deslop: remove AI-generated design patterns

Every AI-generated first draft looks the same: purple-blue gradient hero, Inter font, three cards in a row, emoji icons, "Learn more" buttons. Users recognize it instantly. This skill finds those patterns in frontend code and replaces them with intentional design.

Two modes:

- **Audit.** Score the UI against the 30 checks (6 categories, 5 checks each) and return the scorecard below. Use when the user asks to audit, score, or check a frontend.
- **Fix.** Apply the fixes in this document, highest impact first. Use when the user asks to de-slop, clean up, or humanize a frontend.

Default flow for "make this not look AI-generated": audit first, show the report, then fix. Skip the report only when the user asks for fixes directly.

## What to inspect

- **Local project:** global styles first (`app/globals.css`, `src/index.css`, `tailwind.config.*`, `index.html` for font links and theme colors), then page and section components (hero, features, pricing, footer), then the copy inside them.
- **URL:** take a full-page screenshot if browser tooling is available, and fetch the HTML/CSS. Visual checks (tap targets, animations, layout monotony) need the screenshot; code checks need the source.
- **Pasted code:** audit what was given. Say which checks could not be verified (tap targets, runtime animations) instead of guessing.

## Scoring

- 6 categories, 5 checks each. Every check is PASS or FAIL.
- Category score = (passed / 5) × 100. Overall score = average of the 6 category scores.
- A check fails when the tell is present without a brand or design reason (see [What not to flag](#what-not-to-flag)).

Report format (audit mode returns exactly this):

```markdown
### Overall Score: [X]/100

| Category          | Score | Issues              |
|-------------------|-------|---------------------|
| Colors            | X/100 | [list failures]     |
| Typography        | X/100 | [list failures]     |
| Layout            | X/100 | [list failures]     |
| Copy & Microcopy  | X/100 | [list failures]     |
| Images & Icons    | X/100 | [list failures]     |
| UX & Interaction  | X/100 | [list failures]     |

### Top 3 Priority Fixes
1. [most impactful fix with specific instructions]
2. [second fix]
3. [third fix]

### What's Already Good
[items that passed]
```

## Category 1: Colors

Checks:

- [ ] No purple-to-blue gradient backgrounds
- [ ] No gradient buttons or CTAs
- [ ] 3 colors max (main + grayscale + 1 accent)
- [ ] No box-shadow on more than 2 element types
- [ ] No alternating section background colors (`#f5f5f5`/`#fafafa` pattern)

Find it in code: `linear-gradient` declarations, Tailwind `bg-gradient-to-*` / `from-purple-*` / `to-blue-*` / `from-indigo-*`, gradient classes on buttons, `box-shadow` or `shadow-*` utilities counting more than 2 distinct element types, section wrappers alternating `bg-white` / `bg-gray-50` / `bg-slate-50` / `bg-[#f5f5f5]`.

Fix:

- One solid base color plus one accent. White background, dark text, one accent covers 90% of use cases.
- Flat-color buttons with a subtle hover transition (background or border shift, 150ms).
- Replace shadows with 1px borders. Shadows only on genuinely floating elements: modals, dropdowns, popovers.
- Change section background only at a genuine content shift, not as rhythm decoration.

## Category 2: Typography

Checks:

- [ ] Not using Inter, Roboto, or Open Sans as primary font
- [ ] Headings and body use different font styles (family, weight, or spacing)
- [ ] Clear size contrast between heading levels (not uniform increments)
- [ ] Different line-height for headings (1.1–1.3) vs body (1.6–1.8)
- [ ] Intentional letter-spacing on large headings (not browser default)

Find it in code: `font-family` declarations, Google Fonts links in `index.html`, Tailwind `font-sans` config, heading styles, type scales that step uniformly (16 → 24 → 32px or Tailwind `text-lg` → `text-2xl` → `text-4xl`), a single `leading-normal`/`leading-6` everywhere.

Fix:

- Swap the primary font: DM Sans, Plus Jakarta Sans, Sora, or Geist for English. Noto Sans JP or BIZ UDGothic for Japanese. Match the fallback stack.
- Differentiate headings from body: a second family, or at minimum different weight and tracking.
- Make the hero title dramatically larger, not one step larger.
- Headings: `line-height` 1.1–1.3. Body: 1.6–1.8. The tell is uniformity, not any single value — body at 1.6+ is good typography, keep it.
- Tighten large headings: `letter-spacing: -0.02em` (Tailwind `tracking-tight`).

## Category 3: Layout

Checks:

- [ ] No 3+ consecutive sections with identical 3-column card grids
- [ ] Sections have visually different structures (not all heading → description → cards)
- [ ] Not everything is center-aligned (left-align for body text)
- [ ] Spacing varies between sections (not uniform padding everywhere)
- [ ] Hero is not the standard fullscreen + big text + 2 CTAs template

Find it in code: repeated `grid grid-cols-3 gap-6` blocks, every section following `<h2> <p> <div class="grid grid-cols-3">`, `text-center` / `mx-auto` / `items-center` on all content wrappers, identical `py-24`/`py-16` on every `<section>`, `min-h-screen` heroes with centered `text-5xl` and two buttons.

Fix:

- Mix 1-column, 2-column, and list layouts across the page. Not every grouping needs to be cards.
- Vary section structure: one section can be a split layout, the next a table, the next a list with inline descriptions.
- Left-align by default. Center only heroes and short headings.
- Wider spacing for important sections, tighter for related ones.
- Match hero size and layout to actual content. A tool page can open with the tool itself above the fold instead of a giant headline.

## Category 4: Copy & Microcopy

Checks:

- [ ] No AI buzzwords: unlock, empower, seamless, leverage, streamline, robust, cutting-edge, elevate, harness, delve
- [ ] No 「[X] を、もっと [Y] に」 pattern (Japanese AI copy tell)
- [ ] CTAs are specific ("Calculate your budget"), not generic ("Learn more")
- [ ] Section headings use concrete words, not abstract ones (Features → What you can track)
- [ ] Subtitles are 1 sentence max, not multi-sentence paragraphs

Find it in code: grep the component tree and content files for the buzzword list, `"Learn more"`, `"Get started"`, headings named `Features`, `Solutions`, `Benefits`, `Why choose us`, subtitle `<p>` elements with 2+ sentences under a heading.

Fix:

- Concrete verbs: calculate, compare, find, build, track. Japanese: write what it does (「旅行費用を計算する」).
- CTAs name the action: "Compare 3 tools side by side", not "Learn more".
- Headings state the content: "What you can track", "How it saves you 3 hours/week".
- Subtitles: one sentence. If more is needed, it is body text — place it as body text.
- Do not invent specifics (numbers, features) that the product does not have. If the copy needs a fact the codebase does not contain, ask the user for it.

## Category 5: Images & Icons

Checks:

- [ ] No emoji used as section or card icons
- [ ] Images match the content they illustrate (no mismatched stock photos)
- [ ] No same image reused across multiple pages/sections
- [ ] No AI-generated illustrations with visible artifacts
- [ ] No gradient placeholder boxes where real images should be

Find it in code: emoji literals (🚀 💡 ✨ 🔥 ⭐ 🎯 and friends) inside headings, card headers, and feature lists; `img` tags whose alt/filename is unrelated to the section topic; repeated image paths; placeholder `div`s with gradient backgrounds sized like images.

Fix:

- Replace emoji with SVG icons from a library: Lucide, Heroicons, or Phosphor.
- Every image must match the specific content next to it. A Tokyo Tower photo on an Osaka page fails.
- No unique image available? Design the layout without one. Do not fake it.
- Remove AI-generated illustrations that show artifacts (wrong hands, melted text, inconsistent lighting). Real photos or clean SVGs only.
- If an image is not real, remove it entirely.

## Category 6: UX & Interaction

Checks:

- [ ] First viewport clearly communicates the page's purpose
- [ ] Long content is folded (accordion, tabs, "show more"), not dumped
- [ ] Scroll animations don't block content visibility
- [ ] Touch targets are 44px+ on mobile
- [ ] Max 2 CTA buttons per section

Find it in code: 50+ item grids rendered with no pagination or fold; `IntersectionObserver`, `data-aos`, `whileInView` (framer-motion), or ScrollTrigger attached to every section with opacity 0 → 1 reveals; buttons and icon-only links with small fixed sizes (`p-1`, `h-6 w-6` hit areas); 3+ buttons or links styled as CTAs within one section.

Fix:

- Show 6–9 items initially with "show more" or pagination for the rest.
- Drop scroll-reveal animations, or restrict them to one deliberate moment. They break with View Transitions and fail visually when JS stutters.
- Vary component designs between sections instead of reusing one card component everywhere.
- Minimum 44×44px touch targets on mobile: padding or hit-area extensions, especially on icon buttons.
- Max 2 CTAs per section: one primary, one secondary. Tertiary actions become text links.

## Detection shortcuts

Fast greps to run before reading everything (Tailwind-heavy projects):

- Gradients: `bg-gradient-to|from-purple|from-indigo|from-violet|to-blue|to-indigo|linear-gradient`
- Fonts: `Inter|Roboto|Open Sans|font-sans`
- Shadows: `box-shadow|shadow-(sm|md|lg|xl)` — count element types, not occurrences
- Alternating sections: `bg-gray-50|bg-slate-50|bg-zinc-50|#f5f5f5|#fafafa` on `<section>` wrappers
- Card monotony: `grid-cols-3` — count consecutive occurrences
- Buzzwords: `unlock|empower|seamless|leverage|streamline|robust|cutting-edge|elevate|harness|delve`
- Generic CTAs: `Learn more|Get started|Discover|Explore`
- Emoji icons: `🚀|💡|✨|🔥|⭐|🎯|🚨|📈|⚡`
- Scroll reveals: `IntersectionObserver|data-aos|whileInView|ScrollTrigger|reveal`
- Template hero: `min-h-screen` + `text-center` + `text-5xl|text-6xl` in one block

These are leads, not verdicts. Confirm each hit in context before failing a check.

## Fix order

When fixing, work in this order (visible impact per effort, matching the article's "fastest wins"):

1. **Colors.** Kill gradients, reduce to base + accent, shadows → borders.
2. **Typography.** Swap the font, split heading/body styles, fix line-heights and tracking.
3. **Layout.** Break up repeated card grids, vary section structure and spacing, de-center.
4. **Copy.** Rewrite buzzwords, generic CTAs, and abstract headings with concrete language.
5. **Images & icons.** Emoji → SVG icons, remove fake or mismatched images.
6. **UX.** Fold long lists, prune animations, enforce tap targets and the 2-CTA rule.

Re-audit the affected categories after fixing. The re-audit, not the edit, closes the loop.

## What not to flag

Context decides. The same pattern can be a brand choice on one site and a tell on another:

- **A real design system or brand guide.** If the project documents Inter + purple as brand tokens, that is a brand decision. The gradient on an art portfolio can be intentional; the same gradient on a SaaS landing page is a tell.
- **Accessibility mechanics.** Never remove large touch targets, generous body line-height, or semantic headings to "de-slop". Those are correctness, not style.
- **Component libraries.** Using shadcn/ui, Radix, or similar is not a tell. Slop comes from default arrangement and unmodified output, not from library use. Fix how components are arranged and styled, do not rewrite the library.
- **A single isolated pattern.** One gradient or one emoji does not make a site AI-generated. The verdict comes from stacked tells across categories.
- **Deliberate symmetry or repetition.** Data tables, image galleries, and pricing matrices are legitimately uniform. Flag monotony in marketing structure, not in functional structure.
- **Dark mode and theming.** Fixes must preserve CSS variable systems, `dark:` variants, and existing tokens. De-slop within the project's stack: Tailwind fixes stay in Tailwind utilities, CSS fixes in CSS.

## Fix rules

- Work within the existing stack and tokens. Do not introduce a new CSS framework or rewrite styling architecture to fix a gradient.
- Keep every functional behavior: links, forms, navigation, states (hover, focus, active), responsive breakpoints.
- Preserve focus styles. If removing a shadow or gradient removes the only focus indicator, add an outline.
- Copy rewrites may not add facts. Specifics the product does not have (hours saved, counts, comparisons) require user input first.
- Verify visually when browser tooling is available: screenshot before and after at desktop and mobile widths. Otherwise re-read the changed code against the checks.

## Quick test

When 30 checks are too many, the 5-second version:

1. Screenshot the site at full width. Does it look like every other SaaS landing page?
2. Remove all text. Is the layout still distinctive, or just cards in rows?
3. Would a stranger call it a template?

Any "yes" means there is work to do.

## Source

Based on [How to Make Your Website Not Look AI-Generated (30-Point Checklist)](https://aitoolpick.org/blog/ai-generated-website-checklist/) from AIToolPick. The article's core point: treat AI output as a first draft, then make intentional design choices until the result feels owned.
