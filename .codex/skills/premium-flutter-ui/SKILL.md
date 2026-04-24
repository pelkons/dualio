---
name: premium-flutter-ui
description: Premium Flutter UI implementation for Dualio. Use when Codex builds, edits, audits, or tunes Dualio screens, feed cards, typography, themes, responsive mobile layouts, dark mode, shadows, spacing, visual polish, and fidelity to design/DESIGN.md, design/code.html, and design/screen.png.
---

# Premium Flutter UI

Use this skill when visual quality is the main risk.

## Design Sources

Always read the design files before significant UI work:

- `design/DESIGN.md`
- `design/code.html`
- `design/screen.png`

## Visual Rules

- Match the monochrome editorial/premium system.
- Use Noto Serif for editorial titles and Manrope for body/interface text.
- Use generous whitespace, soft ambient shadows, and 14px card radii.
- Keep card internals visually quieter than the content.
- Support light and dark themes from the first implementation.
- Keep bottom navigation, top header, search pill, floating add button, and feed rhythm aligned with the design.
- Use varied compact card layouts for item types; avoid making every card the same template.
- Avoid hardcoded user-facing strings in widgets.
- Avoid nested decorative cards and marketing-page patterns.
- Do not add loud color accents, gradients, or decorative blobs.

## Mobile Layout Checks

- Check text overflow in compact widths.
- Give fixed-format UI stable dimensions with aspect ratios or constraints.
- Ensure icon-only controls have semantic labels/tooltips where appropriate.
- Verify RTL-sensitive layouts when Hebrew is affected.

## Validation

Prefer visual validation on Android or Flutter preview. If browser preview is used, treat it as approximate and re-check on mobile later.
