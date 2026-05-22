# New Store Quickstart

This guide is written for a Claude Code session spinning up a new store deployment
from the base engine in this repo. Read it top to bottom before touching any files.

---

## What this framework is

A deployable WhatsApp-ordering menu webapp with an AI-powered admin panel.

```
Infrastructure (never changes):        Adapter (only file you edit):
──────────────────────────────         ──────────────────────────────
index.html   customer menu             config.js   store identity
admin.html   admin panel               wrangler.jsonc   CF project name
guide.html   setup guide
```

Firebase holds all live state (theme, menu, settings). The HTML files are the
engine — they read from Firebase and from `config.js`. You never edit the engine
for a new tenant.

---

## Prerequisites

- Cloudflare account with Workers (free tier works)
- Firebase project with Realtime Database enabled
- `wrangler` CLI installed and authenticated (`wrangler login`)
- Node.js (for wrangler)

---

## Steps

### 1 — Clone or copy the template

```bash
git clone https://github.com/arhsmoque/universal-base-adapter-protocol
cp -r universal-base-adapter-protocol/templates/ my-new-store/
cd my-new-store/
```

Rename `config.template.js` to `config.js`:

```bash
mv config.template.js config.js
```

### 2 — Firebase setup

1. Go to https://console.firebase.google.com
2. Create a new project (or reuse an existing one — one Firebase project can host
   multiple stores, each under a different `root` key)
3. Enable **Realtime Database** → choose a region → start in **test mode** for now
4. Copy the database URL from the Data tab (looks like
   `https://YOUR-PROJECT-default-rtdb.REGION.firebasedatabase.app`)

In `config.js`, set:
```js
firebase: {
  url:  'https://YOUR-PROJECT-default-rtdb.REGION.firebasedatabase.app',
  root: 'my_store_name',   // unique key, no spaces — one per store in the same DB
},
```

Firebase security rules — in the Firebase console, set rules to:
```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```
(The admin panel is PIN-protected at the app level. Tighten rules later if needed.)

### 3 — Fill in `config.js`

Edit every section:

| Field | What to change |
|---|---|
| `_STORE_NAME` | Store display name |
| `store.phone` | WhatsApp number, digits only, no `+` |
| `store.currency` | Currency prefix (e.g. `RM`, `$`, `SGD`) |
| `store.sizeLegend` | Size chip labels for drink categories |
| `store.foodAddons` | Optional paid add-ons for food categories |
| `brand.locale` | BCP-47 locale (e.g. `en-MY`, `en-SG`) |
| `ai.model` | OpenRouter model ID (default free model is fine) |
| `defaultTheme` | Starting colors and fonts |
| `defaultMenu` | Starting categories and menu items |

The `defaultMenu` is only used on the very first load when Firebase is empty.
After that, all menu changes are made through the Admin panel.

#### Category fields (in `defaultMenu.categories`):
```js
{ id: 'drinks', label: 'Drinks', emoji: '☕', type: 'drinks' }
//   ^ unique key   ^ nav label   ^ thumbnail  ^ 'drinks' shows size legend chips

{ id: 'specials', label: 'Specials', emoji: '⭐',
  style: 'featured',          // dark premium card wrapper
  title: "Today's Specials",  // overrides large section heading
  subtitle: 'Limited daily',  // italic line below heading
  specialTag: "Chef's Pick"   // badge inside the featured wrapper
}

{ id: 'food', label: 'Food', emoji: '🥪',
  title: 'Food & Bites',
  showAddons: true             // appends store.foodAddons list at bottom
}
```

#### Item fields (in `defaultMenu.items`):
```js
{ id:'d1', cat:'drinks', name:'Coffee', emoji:'☕',
  hot:5, cold:6, frappe:7,   // drink sizes — null = not offered
  price:null, avail:true }

{ id:'f1', cat:'food', name:'Club Sandwich', emoji:'🥪',
  sub:'Club Sandwich',       // groups items under a subsection header
  hot:null, cold:null, frappe:null, price:9.90, avail:true }
```

### 4 — Configure Cloudflare Workers

Edit `wrangler.jsonc` — only change the `name` field:
```jsonc
{
  "name": "my-new-store",   // ← must match your Workers project name
  "compatibility_date": "2026-04-14",
  "assets": { "directory": "." }
}
```

Create the Workers project (first time only):
```bash
wrangler deploy
```

### 5 — Deploy

```bash
wrangler deploy
```

Your store is live at `https://my-new-store.<your-subdomain>.workers.dev`

For a custom domain, add it in the Cloudflare dashboard under Workers → your project → Custom Domains.

---

## First-time Admin setup

1. Go to `https://your-workers-url/admin.html`
2. You'll be prompted to set an **owner PIN** (4–8 digits) — this protects the admin panel
3. Go to **Dev Settings** tab → paste your OpenRouter API key (get one free at openrouter.ai)
4. Go to **Menu** tab → review the seeded items, add/edit/delete as needed
5. Go to **Store** tab → confirm name, phone, hours, and upload a logo if you have one
6. Go to **AI Studio** tab → try the quick chips to customise theme and fonts

---

## Ongoing management (no code changes needed)

| Task | Where |
|---|---|
| Change theme, fonts, colors | Admin → AI Studio (chat or manual) |
| Add/edit/remove menu items | Admin → Menu |
| Mark items sold out | Admin → Menu → toggle availability |
| Change store hours or name | Admin → Store |
| Open/close the store | Admin → Store → toggle |
| Change logo | Admin → Store → upload |
| View recent orders | Admin → Orders |

---

## Upgrading the base engine

When the engine (index.html, admin.html, guide.html) gets an update:

1. Copy the new files from `universal-base-adapter-protocol/templates/` into your store repo
2. Do NOT touch `config.js` or `wrangler.jsonc`
3. Deploy: `wrangler deploy`

All Firebase data (theme, menu, settings) is preserved automatically — the engine
backfills any new rendering fields from `config.js` without overwriting Firebase data.

---

## Multiple stores from one Firebase project

Set a different `firebase.root` in each store's `config.js`:

```js
// Store A
firebase: { url: 'https://...', root: 'store_a' }

// Store B — same Firebase project, different namespace
firebase: { url: 'https://...', root: 'store_b' }
```

Each store has its own isolated data tree under its root key.

---

## File responsibilities (do not confuse these)

| File | Owned by | Touch for |
|---|---|---|
| `config.js` | **You (per tenant)** | Branding, menu, theme, Firebase, AI |
| `wrangler.jsonc` | **You (per tenant)** | Cloudflare project name only |
| `index.html` | **Base engine** | Never — unless upgrading engine |
| `admin.html` | **Base engine** | Never — unless upgrading engine |
| `guide.html` | **Base engine** | Never — unless upgrading engine |

---

## Reference — `config.js` structure

```
APP_CONFIG
├── firebase
│   ├── url          Firebase Realtime DB URL
│   └── root         Namespace key within that DB
├── store
│   ├── name         Display name (shown in header + WhatsApp orders)
│   ├── slogan       Subtitle under store name
│   ├── phone        WhatsApp number (digits only)
│   ├── hours        Opening hours string
│   ├── currency     Price prefix symbol
│   ├── sizeLegend   Array of size chip labels (up to 4)
│   └── foodAddons   Array of { name, price } add-ons
├── brand
│   ├── appName      Shown in loader and WhatsApp message footer
│   ├── adminName    Shown in admin panel title
│   └── locale       BCP-47 locale
├── ai
│   ├── model        OpenRouter model ID
│   ├── systemPrompt Set automatically after APP_CONFIG (references store.name)
│   └── quickChips   Array of { label, prompt } shortcut buttons
├── defaultTheme
│   ├── bg/bg2/bg3   Background layers
│   ├── surface      Card backgrounds
│   ├── primary      Headings, logo
│   ├── accent/accent2 Prices, highlights
│   ├── text/text2/text3 Text hierarchy
│   ├── font_display Heading font (must match Google Fonts link in index.html)
│   └── font_body    Body font (must match Google Fonts link in index.html)
└── defaultMenu
    ├── categories   Array of category objects (see Category fields above)
    └── items        Array of item objects (see Item fields above)
```
