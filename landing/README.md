# Dualio Landing

Static marketing/waitlist site for [dualio.app](https://dualio.app).
Built with [Astro](https://astro.build) — no JavaScript framework, minimal
runtime, deployable as plain static files.

## Local dev

```bash
cd landing
npm install
npm run dev
```

Opens at http://localhost:4321.

## Build

```bash
npm run build      # outputs static files to landing/dist/
npm run preview    # preview the built output
```

## Structure

```
landing/
├── public/
│   ├── icon.png         # app icon (copied from design/)
│   └── screen.png       # hero screenshot (copied from design/)
├── src/
│   ├── components/      # Hero, Features, Waitlist, Nav, Footer
│   ├── layouts/Base.astro
│   ├── pages/
│   │   ├── index.astro  # main landing
│   │   ├── privacy.astro
│   │   └── terms.astro
│   └── styles/global.css   # design tokens mirrored from design/DESIGN.md
└── astro.config.mjs
```

## Design tokens

`src/styles/global.css` defines CSS variables that mirror the colour and type
system declared in [`../design/DESIGN.md`](../design/DESIGN.md). Keep them in
sync if the in-app palette changes.

## Waitlist form

The current `Waitlist.astro` form validates email client-side and shows a
success message — it does **not yet** persist anywhere. Wiring it to a
Supabase `waitlist` table or a form service is the next step.

## Deployment

Designed to deploy as static files to:

- **Cloudflare Pages** — connect the repo, set `landing` as the base
  directory, build command `npm run build`, output `dist`.
- **Vercel / Netlify** — same shape, both support Astro out of the box.

`astro.config.mjs` already sets `site: 'https://dualio.app'`, so absolute URLs
in `og:image` and sitemap are correct.

## Legal pages

`/privacy` and `/terms` are working drafts. They satisfy the minimum needed
for Google OAuth verification and the Play Store privacy-policy field, but
should be reviewed before public launch.
