---
name: i18n-rtl-a11y
description: Internationalization, RTL, and accessibility for Dualio. Use when Codex adds, edits, audits, or reviews user-facing strings, Flutter gen-l10n ARB files, translations for en/he/ru/it/fr/es/de, Hebrew RTL behavior, dynamic text sizing, semantic labels, contrast, locale-aware formatting, and accessibility of mobile UI.
---

# i18n RTL A11y

Use this skill whenever user-facing text, locale behavior, RTL, or accessibility is touched.

## Localization Rules

- Do not hardcode user-facing strings in widgets.
- Use English source strings and ARB translations.
- Maintain locales: `en`, `he`, `ru`, `it`, `fr`, `es`, `de`.
- Keep code, filenames, comments, and default developer-facing identifiers in English.
- Use locale-aware date, number, and plural formatting when needed.

## RTL Rules

- Hebrew must support RTL UI.
- Prefer directional APIs: `EdgeInsetsDirectional`, `AlignmentDirectional`, `TextDirection`-aware layout.
- Avoid left/right assumptions unless they are visual assets that must stay fixed.

## Accessibility Rules

- Add semantic labels for icon-only controls.
- Check text overflow with larger text sizes.
- Preserve sufficient contrast in light and dark themes.
- Keep tap targets mobile-appropriate.
- Avoid relying only on color to communicate state.

## Validation

- Run `flutter gen-l10n` after ARB edits.
- Parse ARB files as JSON if Flutter tooling is unavailable.
- Inspect widgets for hardcoded user-facing strings before finishing.
