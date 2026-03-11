# Gist — Grocery Intelligence, Simplified

A mobile-first grocery list and product health-scoring web app. Search or scan any food product to see its Nutri-Score grade, NOVA processing level, additive risk warnings, and a proprietary **Gist Score** (0–100). All data is stored locally in the browser — no account required.

---

## Project Description

Gist lets users build smart grocery lists and make healthier choices in the store. It fetches real product data from the [Open Food Facts](https://world.openfoodfacts.org/) public API and enriches it with a custom composite health score that penalises high-risk food additives.

### Key Features

- **Grocery List** — Add items by name search or barcode scan, grouped by category
- **Order List** — A secondary list (e.g. for delivery orders)
- **Discover Tab** — Browse top-rated products per category
- **Gist Score** — Proprietary 0–100 score derived from Nutri-Score + additive risk penalties
- **Barcode Scanner** — Uses device camera via the browser `getUserMedia` API
- **Fully Offline-Capable** — All list data persisted in `localStorage`; no backend or login required

---

## Packages

| Package | Role |
|---|---|
| `react` `^18.3.1` | UI framework |
| `react-dom` `^18.3.1` | DOM renderer for React |
| `vite` `^5.4.2` | Build tool & dev server |
| `@vitejs/plugin-react` `^4.3.1` | Vite plugin for React JSX + Fast Refresh |

**External APIs (no key required)**
- [Open Food Facts API v0](https://world.openfoodfacts.org/data) — product search and barcode lookup
- [Google Fonts](https://fonts.google.com/) — Lora typeface loaded via CDN

---

## Local Development Setup

### Prerequisites

- [Node.js](https://nodejs.org/) v18 or later
- [npm](https://www.npmjs.com/) (comes with Node)
- [Git](https://git-scm.com/)

### 1. Clone & Install

```bash
git clone https://github.com/<your-username>/gist.git
cd gist
npm install
```

### 2. Start the Dev Server

```bash
npm run dev
```

Open [http://localhost:5173](http://localhost:5173) in your browser.

### 3. Build for Production

```bash
npm run build       # outputs to /dist
npm run preview     # locally preview the production build
```

---

## GitHub Setup

### Initialize a New Repository

```bash
# From the project root
git init
git add .
git commit -m "Initial commit"

# Create a repo on GitHub (requires GitHub CLI)
gh repo create gist --public --source=. --remote=origin --push

# Or manually link an existing GitHub repo
git remote add origin https://github.com/<your-username>/gist.git
git branch -M main
git push -u origin main
```

### GitHub CLI (optional but recommended)

```bash
brew install gh       # macOS
gh auth login
```

---

## Vercel Deployment

### Option A — Vercel CLI

```bash
npm install -g vercel
vercel login
vercel             # follow the prompts (framework: Vite, output: dist)
```

For subsequent deploys:

```bash
vercel --prod
```

### Option B — Vercel Dashboard (recommended for CI)

1. Go to [vercel.com/new](https://vercel.com/new) and import your GitHub repo
2. Vercel auto-detects Vite. Confirm settings:
   - **Framework Preset:** Vite
   - **Build Command:** `npm run build`
   - **Output Directory:** `dist`
3. Click **Deploy**

Subsequent pushes to `main` trigger automatic redeploys.

> The included `vercel.json` configures SPA client-side routing rewrites so deep links work correctly.

### Environment Variables on Vercel

No environment variables are required for the current version. If you add Supabase (see below), set them in **Project → Settings → Environment Variables**.

---

## Supabase Setup (for future backend features)

Use Supabase when you want to sync lists across devices, add user accounts, or persist data server-side.

### 1. Create a Project

1. Sign up at [supabase.com](https://supabase.com)
2. Create a new project (choose a region close to your users)
3. Note your **Project URL** and **anon public key** from **Settings → API**

### 2. Install the Supabase Client

```bash
npm install @supabase/supabase-js
```

### 3. Add Environment Variables

Create a `.env.local` file in the project root (never commit this file):

```env
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

> Vite exposes env vars prefixed with `VITE_` to the browser bundle.

### 4. Initialize the Client

Create `src/supabase.js`:

```js
import { createClient } from "@supabase/supabase-js";

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);
```

### 5. Add Environment Variables to Vercel

In the Vercel dashboard → **Project → Settings → Environment Variables**, add:

```
VITE_SUPABASE_URL        = https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY   = your-anon-key-here
```

Redeploy after adding variables.

### 6. Example: Sync Grocery Lists

```js
import { supabase } from "./supabase";

// Save a list
await supabase.from("lists").upsert({ user_id: userId, data: listData });

// Load a list
const { data } = await supabase
  .from("lists")
  .select("data")
  .eq("user_id", userId)
  .single();
```

---

## Project Structure

```
gist/
├── index.html                  # App shell with Google Fonts & root div
├── package.json
├── vite.config.js              # Vite + React plugin config
├── vercel.json                 # SPA routing rewrites for Vercel
└── src/
    └── GroceryAppV3_Web.jsx    # Single-file React app (all components & logic)
```

---

## License

Proprietary. Product data provided by [Open Food Facts](https://world.openfoodfacts.org/) under the [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/).
