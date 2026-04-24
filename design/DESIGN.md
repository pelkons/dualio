---
name: Dualio Core
colors:
  surface: '#fdf8f8'
  surface-dim: '#ddd9d8'
  surface-bright: '#fdf8f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f7f3f2'
  surface-container: '#f1edec'
  surface-container-high: '#ebe7e6'
  surface-container-highest: '#e5e2e1'
  on-surface: '#1c1b1b'
  on-surface-variant: '#444748'
  inverse-surface: '#313030'
  inverse-on-surface: '#f4f0ef'
  outline: '#747878'
  outline-variant: '#c4c7c7'
  surface-tint: '#5f5e5e'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#1c1b1b'
  on-primary-container: '#858383'
  inverse-primary: '#c8c6c5'
  secondary: '#5e5e5e'
  on-secondary: '#ffffff'
  secondary-container: '#e1dfdf'
  on-secondary-container: '#626263'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#1c1b1a'
  on-tertiary-container: '#868382'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e5e2e1'
  primary-fixed-dim: '#c8c6c5'
  on-primary-fixed: '#1c1b1b'
  on-primary-fixed-variant: '#474746'
  secondary-fixed: '#e4e2e2'
  secondary-fixed-dim: '#c7c6c6'
  on-secondary-fixed: '#1b1c1c'
  on-secondary-fixed-variant: '#464747'
  tertiary-fixed: '#e6e2df'
  tertiary-fixed-dim: '#cac6c4'
  on-tertiary-fixed: '#1c1b1a'
  on-tertiary-fixed-variant: '#484645'
  background: '#fdf8f8'
  on-background: '#1c1b1b'
  surface-variant: '#e5e2e1'
typography:
  display-lg:
    fontFamily: Noto Serif
    fontSize: 36px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Noto Serif
    fontSize: 24px
    fontWeight: '500'
    lineHeight: '1.3'
  body-md:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  metadata-sm:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: '600'
    lineHeight: '1.4'
    letterSpacing: 0.05em
  label-xs:
    fontFamily: Manrope
    fontSize: 11px
    fontWeight: '500'
    lineHeight: '1.2'
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  margin-mobile: 24px
  gutter: 16px
  stack-lg: 40px
  stack-md: 24px
  stack-sm: 12px
---

## Brand & Style

This design system is built on the principles of **Restrained Minimalism** and **Editorial Sophistication**. It prioritizes a "quiet" interface where the UI recedes to allow content—whether photography, text, or data—to lead the user experience. The personality is confident and effortless, eschewing loud trends for a timeless, curated aesthetic.

The target audience values clarity and a premium feel. The emotional response should be one of calm focus and intellectual ease. By utilizing significant whitespace (negative space) and a monochromatic foundation, the design system creates a digital environment that feels like a high-end print publication.

## Colors

The palette is strictly monochromatic to maintain a "quiet" atmosphere. Pure white is the primary canvas, supported by a range of light greys that provide structure without introducing visual noise. 

- **Primary & Secondary:** Used exclusively for text and core iconography to ensure high legibility and a grounded feel.
- **Surface Tones:** Extremely low-contrast greys are used for card backgrounds and section dividers.
- **Content Accents:** Rather than a traditional accent color, this design system uses subtle, desaturated tints (like Sage-Grey or Slate-Grey) to differentiate content types (e.g., articles vs. events). These accents should never exceed 5-10% saturation.

## Typography

The typography strategy relies on a classic "Serif for Voice, Sans for Function" pairing. 

- **Titles & Display:** `Noto Serif` provides an intellectual, editorial authority. It should be used for all top-level headings and featured quotes. 
- **Body & Interface:** `Manrope` is selected for its modern, balanced proportions. It handles dense information with clarity.
- **Metadata:** All labels, timestamps, and categories use `Manrope` in a slightly smaller size with increased letter spacing and uppercase styling to create a clear visual hierarchy between "content" and "data."

## Layout & Spacing

This design system utilizes a **Fluid Grid** model optimized for mobile density. The layout philosophy is "whitespace as a luxury."

- **Horizontal Margins:** A generous 24px margin on mobile devices prevents the UI from feeling cramped and reinforces the premium, airy feel.
- **Vertical Rhythm:** Large "stack" units (40px+) are used between major content sections to allow the eye to rest.
- **Alignment:** While the grid is fluid, text-heavy editorial sections should favor a strong left-aligned axis to maintain readability.

## Elevation & Depth

Depth in this design system is achieved through **Ambient Shadows** and **Tonal Layering** rather than physical borders.

- **Shadow Character:** Use extremely diffused, large-radius shadows with low opacity (3-5%). The goal is to suggest that an element is resting gently on the surface, not floating far above it.
- **Tonal Layers:** Elevation is often indicated by a shift from a White (#FFFFFF) background to a Subtle Grey (#F5F5F5) surface. 
- **Borders:** Minimal, hairline borders (1px) should only be used when tonal separation is insufficient, utilizing a low-contrast grey (#E9ECEF).

## Shapes

The shape language is defined by **Soft Geometricism**. Elements use a consistent 14px corner radius to soften the interface and make it feel approachable and "modern-classic."

- **Primary Radius:** 14px (represented by `rounded-lg` in the tokens) is the standard for cards, buttons, and input fields.
- **Nested Elements:** When elements are nested inside a 14px container, the internal radius should be reduced to 8px to maintain visual concentricity.
- **Iconography:** Icons should feature rounded caps and corners to match the UI's softness.

## Components

- **Buttons:** Primary buttons use a solid dark charcoal fill with white text. Secondary buttons are "ghost" style with a 1px minimal border or a light grey tonal fill. All buttons use the 14px radius.
- **Cards:** Cards are the primary vehicle for content. Differentiation is achieved through layout—some cards use a vertical stack for imagery, while others use a horizontal split. Subtle background tints identify different content types (e.g., a faint blue-grey for "Case Studies").
- **Chips/Tags:** Used for categorization. These should be pill-shaped with small metadata-style text and low-contrast backgrounds.
- **Input Fields:** Minimalist design with a focus on the bottom border or a very faint grey fill. The focus state is indicated by a subtle darkening of the border or a thin 1px outline.
- **Lists:** Clean, open list items with generous vertical padding (16px+) and hairline dividers that do not span the full width of the screen.
- **Iconography:** Use a consistent 2pt stroke weight. Icons should be functional and unobtrusive, acting as subtle cues rather than focal points.