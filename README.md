# Gist — Grocery Intelligence, Simplified

A native SwiftUI iPhone app that helps you make healthier grocery choices. Search products, scan barcodes, and instantly see Nutri-Score grades, NOVA groups, additive warnings, and a proprietary Gist Score.

## Features

### Lists Tab
- **Recently Viewed** — Products you search or scan appear here after a review step; swipe left to remove, swipe right to move to a list
- **Custom Lists** — Create named lists with a colour swatch (15 colours to choose from); tap to expand and check off items; reorder and delete with edit mode
- **Custom Item** — Add any item manually (name + brand) without an API lookup via the "Custom Item" button
- **Bulk Add (CSV)** — Upload or paste a CSV of up to 50 items (`Product Name, Brand`) for rapid list population; formula-injection strings are sanitised automatically
- **Move to List** — Add any Recently Viewed item to a custom list with one tap
- **Barcode Scanner** — Tap the 📷 button inline with the search bar to scan any product; result opens a review sheet before being saved
- **Product Search** — Inline search with live results showing Nutri-Score, brand, and product image; tap a result to review before adding
- **Review Step** — Tapping any search result opens a detail sheet so you can inspect health scores before confirming the add
- **English-only results** — Non-English product names (CJK, Arabic, Cyrillic, etc.) are filtered out of search results automatically

### Discover Tab
- **Grocery / Order toggle** — Switch between grocery categories (Fruits, Vegetables, Dairy, Meat, etc.) and order categories (Snacks, Baking, Sauces, Canned, Seasonings, etc.)
- **Filter chips** — Tap one or more categories to narrow results; no selection = one item from every category
- **Streaming load** — Products load one by one as each category resolves; skeleton placeholders shown while fetching
- **Expand to add** — Tap any product card to expand it; the product is automatically added to Recently Viewed on first expand
- **Health badges** — Every card shows Nutri-Score, NOVA group, and additive warning count

### Health Scoring
- **Gist Score** — A 0–100 composite health indicator combining Nutri-Score grade with additive risk analysis
- **Nutri-Score** — A–E letter grade for overall nutritional quality
- **NOVA Group** — 1–4 food processing classification
- **Additive Risk** — Count and severity of potentially harmful additives (E-numbers)

### Account & Cloud Sync
- **Sign In / Create Account** — shown on launch; email + password via Supabase
- **Cloud Sync** — lists and recently viewed items synced to Supabase on every change
- **Offline-first** — all data also cached in UserDefaults for use without a connection
- **Admin Panel** — admin users can view all accounts and adjust per-user limits

### Storage
- **Local:** UserDefaults (`groceryLists`, `recentlyViewed`, `productCache` — 24-hour TTL)
- **Cloud:** Supabase — `profiles`, `lists`, `items` tables

## Tech Stack

- SwiftUI + Combine
- AVFoundation (barcode scanning)
- Open Food Facts API (free, open product database)
- iOS 17.0+, Xcode 15+

---

## Supabase Setup (Required for Auth + Cloud Sync)

The app uses [Supabase](https://supabase.com) (free tier) for sign-in, cloud sync, and admin controls.

### Step 1 — Create a Supabase project

1. Go to [supabase.com](https://supabase.com) and create a free project
2. In the dashboard go to **Settings → API** and copy:
   - **Project URL** (e.g. `https://abcdefgh.supabase.co`)
   - **anon / public key**

### Step 2 — Run the schema

1. In the Supabase dashboard go to **SQL Editor**
2. Paste and run the contents of [`supabase_schema.sql`](supabase_schema.sql)

This creates the `profiles`, `lists`, and `items` tables with Row Level Security enabled.

### Step 3 — Add your credentials to the app

Open `Gist/Gist/Services/SupabaseConfig.swift` and update the two constants:

```swift
static let url     = "https://YOUR_PROJECT_REF.supabase.co"  // ← your Project URL
static let anonKey = "YOUR_ANON_KEY"                          // ← your anon/public key
```

### Step 4 — Promote yourself to admin

After signing up in the app, run this once in the Supabase SQL Editor:

```sql
update public.profiles set role = 'admin' where email = 'your@email.com';
```

Your Account tab will then show an **Open Admin Panel** button where you can adjust per-user list and item limits.

### Step 5 — Migrate an existing database (upgrading from an older version)

If you already have a Supabase project running the old schema (which stored an `emoji` column on lists), run these three statements in the SQL Editor to migrate to the new `color` column:

```sql
alter table public.lists rename column emoji to color;
alter table public.lists alter column color set default '#7ac94b';
update public.lists set color = '#7ac94b' where color not like '#%';
```

Fresh installs can skip this step — `supabase_schema.sql` already uses `color`.

---

## Turso Setup (Alternative to Supabase)

[Turso](https://turso.tech) is a SQLite-compatible edge database. Because Turso has no built-in auth, sign-up and sign-in run through two Vercel serverless functions included in the web repo (`Gist`). The Swift app hits those same endpoints — no Turso credentials ever touch the device.

> **Prerequisite:** Deploy the Gist web repo to Vercel first and complete its Turso setup steps (Steps 1–5 in that README). You only need one Turso database and one set of Vercel functions for both apps.

### Step 1 — Set the API base URL

Open `Gist/Gist/Services/TursoConfig.swift` and replace the placeholder:

```swift
static let apiBase = "https://YOUR_VERCEL_URL"
// e.g. "https://gist-abc123.vercel.app"
```

### Step 2 — Swap the service implementations

Replace `AuthService` and `CloudStorageService` with their Turso counterparts.

In every file that imports or references `AuthService.shared`, change it to `TursoAuthService.shared`.
In every file that references `CloudStorageService.shared`, change it to `TursoCloudService.shared`.

The public API of both replacements is identical to the originals — no other code changes are required.

Alternatively, open `GistApp.swift` (or whichever file injects the auth object) and update the state object:

```swift
// Before
@StateObject private var auth = AuthService.shared

// After
@StateObject private var auth = TursoAuthService.shared
```

### Step 3 — Build and run

Select a simulator or device and press **Cmd + R**. The sign-in screen will appear. Sign up, and your lists sync to Turso via the Vercel API.

### Step 4 — Promote yourself to admin

After signing up in the app, run from your Mac terminal:

```bash
# Requires the Gist web repo to be cloned alongside this one
TURSO_URL=libsql://gist-<org>.turso.io \
TURSO_TOKEN=your-auth-token \
ADMIN_EMAIL=you@email.com \
node ../Gist/scripts/setup-turso.js --promote
```

---

## Opening the Project

### In Xcode

1. Clone the repo:
   ```bash
   git clone https://github.com/OpenTechnology14/Gist-Swift.git
   cd Gist-Swift/Gist
   ```
2. Open the project:
   ```bash
   open Gist.xcodeproj
   ```
3. Select a simulator or connected device from the toolbar
4. Press **Cmd + R** to build and run

### iOS Simulator in VS Code

VS Code supports iOS development via the **Swift extension** and **iOS Simulator**.

1. Install required extensions in VS Code:
   - [Swift](https://marketplace.visualstudio.com/items?itemName=sswg.swift-lang) by the Swift Server Work Group
   - [iOS Simulator](https://marketplace.visualstudio.com/items?itemName=sweetpad.sweetpad) by SweetPad

2. Install `xcode-build-server` (enables Swift IntelliSense in VS Code):
   ```bash
   brew install xcode-build-server
   ```

3. Generate the build server config from inside the project folder:
   ```bash
   cd Gist-Swift/Gist
   xcode-build-server config -project Gist.xcodeproj -scheme Gist
   ```

4. Open the project folder in VS Code:
   ```bash
   code .
   ```

5. Open the **SweetPad panel** (sidebar icon) — it will detect available simulators automatically

6. Click **Build & Run** in the SweetPad panel, or use the command palette:
   `Cmd + Shift + P` → `SweetPad: Build and Run`

7. The iOS Simulator will launch with the Gist app running

> **Note:** Xcode must be installed on your Mac for the simulator to work — VS Code uses Xcode's toolchain under the hood.

---

## Publishing to the App Store

### Prerequisites

- An active [Apple Developer Program](https://developer.apple.com/programs/) membership ($99/year)
- Xcode 15+ installed
- App icons (1024x1024 required) added to `Assets.xcassets/AppIcon.appiconset`

### Step 1 — Configure signing in Xcode

1. Open `Gist.xcodeproj` in Xcode
2. Select the **Gist** target → **Signing & Capabilities**
3. Check **Automatically manage signing**
4. Set your **Team** to your Apple Developer account
5. Update the **Bundle Identifier** if needed (currently `com.opentech.gist`)

### Step 2 — Create the app in App Store Connect

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **+** → **New App**
3. Fill in: name (Gist), platform (iOS), bundle ID (`com.opentech.gist`), SKU
4. Complete the app listing: description, screenshots, category (Food & Drink), privacy policy URL

### Step 3 — Archive and upload

1. In Xcode, set the scheme destination to **Any iOS Device (arm64)**
2. Menu → **Product** → **Archive**
3. Once archived, the **Organizer** window opens automatically
4. Click **Distribute App** → **App Store Connect** → **Upload**
5. Follow the prompts — Xcode will sign and upload the build

### Step 4 — Submit for review

1. In App Store Connect, go to your app → **TestFlight** to test the build first (recommended)
2. When ready, go to the **App Store** tab → select your build → fill in **What's New**
3. Click **Submit for Review**
4. Apple's review typically takes 24–48 hours

### Privacy notes for review

The app uses the camera for barcode scanning and collects email/password for authentication. Make sure your App Store Connect privacy nutrition label reflects:
- **Camera** — used for barcode scanning (not linked to identity)
- **Email address** — collected for account creation and sign-in
- **User content** (lists, items) — stored in your Supabase project, not shared with third parties

---

## Future Features

- **Custom New Items + Review Process** — Enhanced custom item creation with a full review flow matching the search/scan experience, including health score lookup and confirmation before adding to a list
- **Other Languages** — Support for non-English product databases and localised UI (French, Spanish, German, and more) using Open Food Facts' multilingual data
- **Healthier Alternatives** — When viewing a product, suggest similar items with a higher Gist Score in the same category
- **Meal Planning** — Build weekly meal plans from saved lists and get an at-a-glance nutritional summary for the week
- **Widgets & Apple Watch** — Home screen widgets showing your active list and an Apple Watch companion app for quick check-offs while shopping

---

## Data Sources

Product data is provided by [Open Food Facts](https://world.openfoodfacts.org) under the [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/).
