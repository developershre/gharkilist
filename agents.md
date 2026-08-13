I'm building a mobile app called "Bhandar Khata" (working name) — a household pantry/grocery inventory tracker for Indian households, built in Flutter. Here's the full concept:

PROBLEM
Indian households manually walk through their kitchen/pantry every month to check what's running low, then make a grocery list. This is entirely manual and mental — there's no digital tool built for how Indian households actually shop and stock.

CORE CONCEPT
An app where users track their pantry inventory by adding items from a pre-built catalog, mark items as low/out, and auto-generate a categorized shopping list/cart each month.

KEY DESIGN DECISION: NO BARCODE SCANNING AS PRIMARY INPUT
Most Indian household staples (loose atta, dal, spices, rice bought by weight) have no barcode — they come in plain plastic bags from local kirana stores, not branded packaging. So classic barcode scanning was considered and rejected as the primary input method. Instead, the app is built around a hand-curated catalog:
- ~150-200 common Indian household items (grains, dals, spices, oils, dairy, cleaning supplies, personal care)
- Each item has: English name, Hindi name, category, common regional aliases (e.g., toor dal = tuvar dal = arhar dal — same lentil, different regional names), typical units (kg, g, packet, katori)
- A known hard problem: many dal/lentil varieties look visually near-identical, so true AI-based visual classification is deliberately deferred until real usage data exists to train on

BUILD ORDER (important — sequence matters)
1. Catalog data comes FIRST, before UI polish — the full 150-200 item data set (bilingual names, categories, units, aliases) is the foundation everything else depends on.
2. Then the core UI: empty state, list view, add flow.
3. Scanning exists as a UI entry point from day one, but is NOT AI-powered yet (see below).
4. AI-based image recognition for the Scan button is an explicit LATER phase, not part of v1 — it does not block launch.

APP FLOW (v1)

Empty state (first open, no items yet):
- Just a list view with a dotted-outline "+" card/button, centered — minimal, inviting first action
- Tapping "+" offers two paths: Scan, or Browse/Search

Scan path (pre-AI placeholder behavior):
- Tap Scan → camera opens → photo is captured
- Immediately routes to the Search/Catalog picker (no recognition happens yet)
- User manually finds and confirms the correct item
- The captured photo is saved and linked to whichever item the user confirms — this quietly builds a labeled photo dataset for free, so when AI recognition is built later, there's already real training data instead of starting from zero
- Quantity stepper (kg / g / packet / katori) → item added to inventory

Browse/Search path:
- Category tiles (grains, dals, spices, oils, dairy, cleaning, personal care, etc.) → item grid within category (photo + English + Hindi name) → search bar as fallback for anything not visible → tap item → quantity stepper → added to inventory

After first item is added:
- Home screen switches from empty state to a populated List view of pantry items, grouped by category
- The "+" persists as a smaller add button/FAB with the same two paths (Scan / Browse)
- User can freely sort, reorder, and remove items — no restrictions below the item cap

Sharing:
- Finished list can be shared via WhatsApp as formatted text — most Indian households already order informally through WhatsApp to their local kirana, so this beats building in-app checkout

MONETIZATION MODEL
- Every action (add, remove, sort, reorder) is completely free — no feature is paywalled
- The ONLY paid lever is inventory SIZE: free tier is capped at roughly 10-15 tracked items at once; paid tier removes/raises that cap
- Reasoning: unlimited free items would make this feel like a generic to-do list app with no reason to pay
- Future paid-tier value beyond the cap: cloud sync across devices, shared household lists (multiple family members editing one pantry), possibly unlimited AI scans once that phase exists (since each AI scan will carry an API cost)

TARGET AUDIENCE
Younger, urban Indian users who are already comfortable with online shopping / quick-commerce apps (Blinkit, Zepto, Swiggy Instamart), but currently have no good way to track household stock digitally.

TECH APPROACH
- Framework: Flutter (locked in) — single codebase for Android and iOS
- Local-first: SQLite on-device (via the sqflite package) for the item catalog and each household's pantry data — works fully offline for the core add/browse/list flow
- Item images served from a lightweight backend/cloud storage by URL — not bundled into the app
- Camera capture via Flutter's camera/image_picker packages
- Item cap enforcement will need a lightweight account + server-side check eventually, since a purely local SQLite cap is trivially bypassable
- Note: once AI scanning is added later, that flow will require internet + a backend endpoint calling a vision AI API — unlike the offline-first tap/browse flow