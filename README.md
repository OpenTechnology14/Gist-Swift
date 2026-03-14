# Gist — Grocery Intelligence, Simplified

A native SwiftUI iPhone app that helps you make healthier grocery choices. Search products, scan barcodes, and instantly see Nutri-Score grades, NOVA groups, additive warnings, and a proprietary Gist Score.

## Features

- **Grocery List** — Search products, scan barcodes, organize by category, check off items
- **Order List** — Separate order list with the same search and scan capabilities
- **Discover** — Browse top-rated products by category (Fruits, Vegetables, Dairy, Snacks, and more)
- **Gist Score** — A 0–100 health indicator combining Nutri-Score with additive risk analysis
- **Barcode Scanner** — Point your camera at any product barcode for instant nutrition info
- **Offline-first** — All list data stored locally on device via UserDefaults

## Tech Stack

- SwiftUI + Combine
- AVFoundation (barcode scanning)
- Open Food Facts API (free, open product database)
- iOS 17.0+, Xcode 15+

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

The app uses the camera for barcode scanning. Make sure your App Store Connect privacy nutrition label reflects:
- **Camera** — used for barcode scanning (not linked to identity)
- No data collected or transmitted to your servers

---

## Data Sources

Product data is provided by [Open Food Facts](https://world.openfoodfacts.org) under the [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/).
