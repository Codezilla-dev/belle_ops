# Belle Ops — Visit Day Tool

An internal tool for the ops coordinator who runs a day of in-home visits: see the
whole region's day at a glance, spot the visits about to fall through, and put a
waiting member into the hole a cancellation leaves behind.

## Run it

```bash
bin/setup
```

That installs gems and npm packages, creates and seeds the database, and starts the
dev server (Rails + Vite) at http://localhost:3000.

Already set up? Just:

```bash
bin/dev
```

Reset the demo data at any time:

```bash
bin/rails db:seed
```

Tests:

```bash
bin/rails test
```

## Stack

Rails 8.1, Inertia.js + React via Vite, Tailwind CSS, SQLite.

## Notes

"Today" is pinned to **2026-06-29** (the dataset's day) and "now" to **12:00 ET**, so
the app behaves deterministically no matter when you run it. See
`config/initializers/belle.rb`.
