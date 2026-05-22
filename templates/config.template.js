/**
 * config.js — [Your Store Name]
 *
 * ┌─────────────────────────────────────────────────────────────┐
 * │  THIS IS THE ONLY FILE YOU EDIT FOR A NEW DEPLOYMENT.       │
 * │  index.html, admin.html, guide.html, wrangler.jsonc are     │
 * │  the base engine — leave them alone.                        │
 * └─────────────────────────────────────────────────────────────┘
 *
 * QUICK START
 * ───────────
 * 1. Rename this file to config.js
 * 2. Replace every value below with your store's details
 * 3. Set firebase.url → your Firebase Realtime Database URL
 * 4. Set firebase.root → a unique namespace key for this store
 * 5. Edit wrangler.jsonc: set "name" to your Cloudflare Workers project
 * 6. Deploy:  wrangler deploy
 *
 * After first deploy, all live settings (theme, menu, open/close, PIN)
 * are managed through the Admin panel at /admin.html — no code changes needed.
 *
 * TO UPGRADE THE BASE ENGINE
 * ──────────────────────────
 * Copy a fresh index.html / admin.html / guide.html from the template repo.
 * Your config.js is untouched during upgrades.
 */

// ── Reused below so systemPrompt can reference it without circular reference ───
const _STORE_NAME = 'My Store';    // ← Start here

const APP_CONFIG = {

  // ── Firebase Realtime Database ──────────────────────────────────────────────
  // Create a free project at https://console.firebase.google.com
  // Enable Realtime Database → copy the URL from the Data tab.
  firebase: {
    url:  'https://YOUR-PROJECT-default-rtdb.REGION.firebasedatabase.app',
    root: 'my_store',   // Unique namespace — use letters and underscores only
  },

  // ── Store Defaults ──────────────────────────────────────────────────────────
  // Shown until your Admin panel saves data to Firebase for the first time.
  store: {
    name:     _STORE_NAME,
    slogan:   'Your tagline here',
    phone:    '60123456789',         // WhatsApp number — digits only, no + or spaces
    hours:    '9:00 AM – 9:00 PM daily',
    currency: 'RM',                  // Prefix shown before every price

    // Up to 4 labels for the drink size chips
    sizeLegend: ['HOT 8oz', 'COLD 12oz', 'LARGE 16oz'],

    // Optional paid add-ons shown at the bottom of categories with showAddons: true
    foodAddons: [
      { name: 'Extra Shot', price: 3 },
      // { name: 'Extra Cheese', price: 2 },
    ],
  },

  // ── App Branding ────────────────────────────────────────────────────────────
  brand: {
    appName:   _STORE_NAME,
    adminName: `${_STORE_NAME} Admin`,
    locale:    'en-MY',   // BCP-47 locale tag (affects number/date formatting)
  },

  // ── AI Studio ───────────────────────────────────────────────────────────────
  // The AI key is stored securely in Firebase via Admin > Dev Settings.
  // Never put the key in this file.
  ai: {
    model: 'google/gemma-4-26b-it:free',   // Any OpenRouter model ID

    systemPrompt: null,   // Set below after APP_CONFIG is fully defined

    // Quick-access buttons in the AI chat panel
    quickChips: [
      { label: '↩ Reset Theme',    prompt: 'Reset all theme colors and fonts back to the original default' },
      { label: '✏️ Change Slogan', prompt: 'Change the slogan to: ' },
      { label: '✅ All Available', prompt: 'Mark all menu items as available' },
      // Add more chips as needed — max 6 recommended
    ],
  },

  // ── Default Theme ───────────────────────────────────────────────────────────
  // Applied on first load; overridden permanently once saved via Admin > AI Studio.
  // font_display / font_body must match the Google Fonts families in index.html <head>.
  defaultTheme: {
    bg:           '#FFFFFF',    // Page background
    bg2:          '#F8F8F8',    // Subtle alternate background
    bg3:          '#EFEFEF',    // Borders, chips
    surface:      '#FFFFFF',    // Card / panel backgrounds
    primary:      '#1A1A1A',    // Headings, logo text
    accent:       '#E67E22',    // Prices, active tabs, highlights
    accent2:      '#F39C12',    // Secondary accent (hover states)
    text:         '#1A1A1A',    // Body text
    text2:        '#555555',    // Secondary text
    text3:        '#999999',    // Muted labels
    font_display: "'Georgia', serif",         // Heading font — must match <link> in index.html
    font_body:    "'Arial', sans-serif",      // Body font   — must match <link> in index.html
  },

  // ── Default Menu ────────────────────────────────────────────────────────────
  // Seeded into Firebase on first run. All further changes are made in the Admin panel.
  //
  // ── CATEGORY FIELDS ──────────────────────────────────────────
  //   id           Unique key (lowercase, no spaces)
  //   label        Display name in the navigation bar
  //   emoji        Shown before label in nav and section header
  //   type         'drinks'     → shows hot/cold/frappe size legend chips
  //   style        'featured'   → section renders in a dark premium card wrapper
  //   title        Override for the large section heading (defaults to label)
  //   subtitle     Italic line below the heading
  //   specialTag   Badge text inside the featured wrapper
  //   showAddons   true → appends store.foodAddons list at the bottom
  //
  // ── ITEM FIELDS ──────────────────────────────────────────────
  //   id           Unique key
  //   cat          Category id this item belongs to
  //   name         Displayed item name
  //   desc         Short italic description (optional)
  //   emoji        Thumbnail when no img_url is set
  //   hot          Price for hot size   (null = not offered)
  //   cold         Price for cold size  (null = not offered)
  //   frappe       Price for frappé     (null = not offered)
  //   price        Fixed price for non-drink items
  //   avail        false → shows "Sold Out" badge
  //   img_url      Photo URL (set via Admin panel)
  //   sub          Subsection header — groups items within a category
  //   addons       Addon groups (managed entirely in Admin panel)
  defaultMenu: {
    categories: [
      { id: 'drinks',   label: 'Drinks',   emoji: '☕', type: 'drinks' },
      { id: 'food',     label: 'Food',     emoji: '🥪', title: 'Food & Bites', showAddons: true },
      { id: 'specials', label: 'Specials', emoji: '⭐', style: 'featured', title: "Today's Specials", specialTag: "Chef's Pick" },
    ],
    items: [
      // Replace these starter items with your actual menu in the Admin panel
      { id:'d1', cat:'drinks', name:'Coffee',     desc:'',              emoji:'☕', hot:5,    cold:6,    frappe:7,    price:null, avail:true },
      { id:'d2', cat:'drinks', name:'Tea',        desc:'',              emoji:'🍵', hot:4,    cold:5,    frappe:null, price:null, avail:true },
      { id:'f1', cat:'food',   name:'Toast',      desc:'With butter',   emoji:'🍞', hot:null, cold:null, frappe:null, price:4.00, avail:true },
      { id:'f2', cat:'food',   name:'Sandwich',   desc:'',              emoji:'🥪', hot:null, cold:null, frappe:null, price:7.00, avail:true },
      { id:'s1', cat:'specials', name:"Today's Special", desc:'Ask staff', emoji:'⭐', hot:null, cold:null, frappe:null, price:12.00, avail:true },
    ],
  },
};

// ── AI System Prompt ────────────────────────────────────────────────────────────
// Defined after APP_CONFIG so it can reference APP_CONFIG.store.name without a
// circular reference inside the object literal above.
APP_CONFIG.ai.systemPrompt = `You are a helpful assistant for a business called ${APP_CONFIG.store.name}.

Help the owner manage their menu, theme, and store settings through natural conversation.

OUTPUT FORMAT for theme/CSS changes — return JSON only, no prose outside the object:
{
  "understood": "brief restatement of what was asked",
  "action": "what you changed",
  "changes": { "theme": {}, "store": {}, "menu_availability": {} },
  "suggestion": "one optional tip (omit if none)"
}

RULES:
- Only change what is explicitly requested
- Never touch the WhatsApp button color (must stay green)
- Never change layout, spacing, or grid structure
- Never change store phone or name unless explicitly asked
- When in doubt, do less not more

CONTEXT: Full current store state is provided as YAML before each message.`;
