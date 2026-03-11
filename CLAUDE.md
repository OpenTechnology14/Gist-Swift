# Gist — Claude Project Prompt

## Project Overview

**Gist** is a mobile-first grocery list and food health-scoring web app built with React + Vite. It is a single-page application (SPA) with one source file: `src/GroceryAppV3_Web.jsx`.

Users can search for food products by name or scan barcodes. The app fetches data from the Open Food Facts public API and displays a proprietary **Gist Score** (0–100) derived from the product's Nutri-Score grade and a penalty system for high-risk food additives (E-numbers).

All user data (grocery lists, categories, order lists) is stored in `localStorage` under the key `gist_grocery_v1`. There is no backend, authentication, or database in the current version.

---

## Tech Stack

- **React 18** — UI framework
- **Vite 5** — build tool and dev server
- **Open Food Facts API** — public REST API, no key required
- **localStorage** — client-side persistence
- **Google Fonts (Lora)** — typography loaded via CDN link in `index.html`

---

## Key Architecture

### Scoring System (`src/GroceryAppV3_Web.jsx`, lines 1–76)
- `NUTRI_BASE` maps Nutri-Score grades (a–e) to base scores (90, 72, 54, 36, 18)
- `ADDITIVE_RISK` maps E-number codes to risk levels 0–3
- `computeGistScore(grade, additives)` → final score after subtracting `risk × 3` per additive

### API Layer (lines ~793–860)
- `fetchByBarcode(barcode)` — GET `https://world.openfoodfacts.org/api/v0/product/{barcode}.json`
- `fetchBySearch(query)` — GET `https://world.openfoodfacts.org/cgi/search.pl` with JSON output
- `fetchSuggestions(tag)` — used by Discover tab to browse products by category tag

### Storage Helpers (lines ~180–192)
- `loadData()` / `saveData(data)` — JSON serialisation to/from `localStorage`

### UI Components
- `RingScore` — SVG circular progress ring displaying the Gist Score
- `HealthBadge` — colour-coded Nutri-Score label badge
- `GistScoreBadge` — outlined badge showing the numeric Gist Score
- `AdditivesWarning` — amber warning block listing high-risk additives
- `PageShell` — sticky header + back button wrapper for static pages
- `BarcodeScanner` — uses `navigator.mediaDevices.getUserMedia` for live camera feed

### App Tabs
1. **Grocery List** — search/scan to add items, grouped by category, check off items
2. **Order List** — secondary list (e.g. delivery), same UX as Grocery List
3. **Discover** — browse top-rated products by category (Open Food Facts tags)
4. **More** — links to Help, About, Privacy Policy, Terms of Use pages

---

## Setup Instructions for Claude

When helping set up or extend this project, follow these steps:

### 1. Local Development

```bash
git clone https://github.com/<username>/gist.git
cd gist
npm install
npm run dev
# → http://localhost:5173
```

### 2. Build & Preview

```bash
npm run build    # outputs to /dist
npm run preview  # serves /dist locally
```

### 3. Deploy to Vercel

The repo includes `vercel.json` with SPA rewrites. Vercel auto-detects Vite.

```bash
npm install -g vercel
vercel login
vercel --prod
```

Or connect the GitHub repo in the Vercel dashboard. No environment variables are required for the base app.

### 4. Add Supabase (when syncing data or adding auth)

```bash
npm install @supabase/supabase-js
```

Create `.env.local`:

```
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

Create `src/supabase.js`:

```js
import { createClient } from "@supabase/supabase-js";
export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);
```

Add the same env vars to Vercel → Settings → Environment Variables.

---

## Coding Conventions

- All components and logic live in **one file**: `src/GroceryAppV3_Web.jsx`
- Styles are written as inline JS style objects (no CSS modules or Tailwind)
- The serif font `'Lora'` from Google Fonts is used throughout for brand consistency
- Brand colours: dark brown `#2a2118` (header/text), green `#7ac94b` (primary action), cream `#f5f2ec` (background)
- No TypeScript — plain JSX only
- No router library — navigation is managed with a `page` state string

---

## Common Tasks for Claude

- **Add a new tab**: Add a new case to the main `page` state switch and a tab button in the bottom nav bar
- **Add a new product field**: Extend the `fetchByBarcode`/`fetchBySearch` result parsing to extract and display the field
- **Add Supabase auth**: Use `supabase.auth.signInWithOAuth` with GitHub or Google provider
- **Add a new additive**: Add the E-number and risk level (0–3) to the `ADDITIVE_RISK` object
- **Adjust Gist Score formula**: Modify `computeGistScore` — the penalty multiplier is currently `risk × 3`

---

## Files

```
gist/
├── CLAUDE.md                   ← this file
├── README.md                   ← user-facing setup guide
├── index.html                  ← HTML shell + Google Fonts
├── package.json
├── vite.config.js
├── vercel.json                 ← SPA routing config
└── src/
    └── GroceryAppV3_Web.jsx    ← entire app (components, logic, styles)
```
