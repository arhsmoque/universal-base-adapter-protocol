#!/bin/bash
set -e

CONFIG_FILE="design.config.json"
DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
  DRY_RUN=true
fi

if [ ! -f "$CONFIG_FILE" ]; then
  echo '{"status":"error","summary":"design.config.json not found"}'
  exit 1
fi

# Read design tokens from JSON using a tiny Node script
read_config() {
  node -e "
    const fs = require('fs');
    const config = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));
    console.log(JSON.stringify(config.designTokens));
  "
}

TOKENS=$(read_config)

# Extract values (using jq if available, else fallback to grep/sed)
if command -v jq &> /dev/null; then
  FONT_SANS=$(echo "$TOKENS" | jq -r '.fontFamily.sans | map("\"" + . + "\"") | join(", ")')
  PRIMARY_COLOR=$(echo "$TOKENS" | jq -r '.primaryColor')
  ENERGY_DEFAULT=$(echo "$TOKENS" | jq -r '.energyDefault')
  SPACING_SCALE=$(echo "$TOKENS" | jq -r '.spacingScale')
  BORDER_RADIUS=$(echo "$TOKENS" | jq -r '.borderRadius')
  MOTION_SPEED=$(echo "$TOKENS" | jq -r '.motionSpeed')
  SHADOW_INTENSITY=$(echo "$TOKENS" | jq -r '.shadowIntensity')
  CONTAINER_WIDTH=$(echo "$TOKENS" | jq -r '.containerMaxWidth')
  FOCUS_RING_COLOR=$(echo "$TOKENS" | jq -r '.focusRing.color')
  FOCUS_RING_WIDTH=$(echo "$TOKENS" | jq -r '.focusRing.width')
  FOCUS_RING_OFFSET=$(echo "$TOKENS" | jq -r '.focusRing.offset')
  BREAKPOINTS=$(echo "$TOKENS" | jq -r '.breakpoints')
else
  # Fallback: use grep/sed (simplified)
  echo "⚠️ jq not installed – using limited fallback. Install jq for full functionality." >&2
  FONT_SANS='"Inter", "system-ui"'
  PRIMARY_COLOR="#2563EB"
  ENERGY_DEFAULT="precise"
  SPACING_SCALE="comfortable"
  BORDER_RADIUS="default"
  MOTION_SPEED="normal"
  SHADOW_INTENSITY="default"
  CONTAINER_WIDTH="standard"
  FOCUS_RING_COLOR="#2563EB"
  FOCUS_RING_WIDTH="2px"
  FOCUS_RING_OFFSET="2px"
fi

if [ "$DRY_RUN" = true ]; then
  echo '{"status":"dry_run","summary":"Would regenerate tailwind.config.js and src/index.css"}'
  exit 0
fi

# Backup existing files
cp tailwind.config.js tailwind.config.js.backup 2>/dev/null || true
cp src/index.css src/index.css.backup 2>/dev/null || true

# Generate new tailwind.config.js
cat > tailwind.config.js << EOF
/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ["class"],
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      fontFamily: {
        sans: [$FONT_SANS],
        serif: ["Georgia", "serif"],
        mono: ["monospace"],
      },
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      spacing: getSpacing($SPACING_SCALE),
      borderRadius: getBorderRadius($BORDER_RADIUS),
      boxShadow: getShadows($SHADOW_INTENSITY),
      animation: getAnimations($MOTION_SPEED),
      keyframes: {
        "accordion-down": { from: { height: "0" }, to: { height: "var(--radix-accordion-content-height)" } },
        "accordion-up": { from: { height: "var(--radix-accordion-content-height)" }, to: { height: "0" } },
        "gentle-fade": { "0%": { opacity: "0", transform: "translateY(4px)" }, "100%": { opacity: "1", transform: "translateY(0)" } },
      },
      screens: $BREAKPOINTS,
    },
  },
  plugins: [require("tailwindcss-animate")],
};

function getSpacing(scale) {
  const scales = {
    compact: { DEFAULT: "0.125rem", 0: "0", 1: "0.25rem", 2: "0.5rem", 3: "0.75rem", 4: "1rem", 5: "1.25rem", 6: "1.5rem", 8: "2rem", 10: "2.5rem", 12: "3rem", 16: "4rem", 20: "5rem" },
    comfortable: { DEFAULT: "0.25rem", 0: "0", 1: "0.25rem", 2: "0.5rem", 3: "0.75rem", 4: "1rem", 5: "1.5rem", 6: "2rem", 8: "3rem", 10: "4rem", 12: "5rem", 16: "6rem", 20: "8rem" },
    spacious: { DEFAULT: "0.5rem", 0: "0", 1: "0.5rem", 2: "1rem", 3: "1.5rem", 4: "2rem", 5: "2.5rem", 6: "3rem", 8: "4rem", 10: "6rem", 12: "8rem", 16: "10rem", 20: "12rem" },
  };
  return scales[scale] || scales.comfortable;
}

function getBorderRadius(style) {
  const radii = {
    sharp: { lg: "0.25rem", md: "0.125rem", sm: "0.0625rem", none: "0", full: "9999px" },
    default: { lg: "0.5rem", md: "0.375rem", sm: "0.25rem", none: "0", full: "9999px" },
    pill: { lg: "1rem", md: "0.75rem", sm: "0.5rem", none: "0", full: "9999px" },
  };
  return radii[style] || radii.default;
}

function getShadows(intensity) {
  const shadows = {
    subtle: { sm: "0 1px 2px 0 rgba(0, 0, 0, 0.03)", DEFAULT: "0 1px 3px 0 rgba(0, 0, 0, 0.05)", md: "0 4px 6px -1px rgba(0, 0, 0, 0.05)", lg: "0 10px 15px -3px rgba(0, 0, 0, 0.05)" },
    default: { sm: "0 1px 2px 0 rgba(0, 0, 0, 0.05)", DEFAULT: "0 1px 3px 0 rgba(0, 0, 0, 0.1)", md: "0 4px 6px -1px rgba(0, 0, 0, 0.1)", lg: "0 10px 15px -3px rgba(0, 0, 0, 0.1)" },
    prominent: { sm: "0 1px 2px 0 rgba(0, 0, 0, 0.1)", DEFAULT: "0 1px 3px 0 rgba(0, 0, 0, 0.2)", md: "0 4px 6px -1px rgba(0, 0, 0, 0.2)", lg: "0 10px 15px -3px rgba(0, 0, 0, 0.2)" },
  };
  return shadows[intensity] || shadows.default;
}

function getAnimations(speed) {
  const speeds = {
    slow: { "accordion-down": "accordion-down 0.4s ease-out", "accordion-up": "accordion-up 0.4s ease-out", "gentle-fade": "gentle-fade 0.5s ease-out" },
    normal: { "accordion-down": "accordion-down 0.2s ease-out", "accordion-up": "accordion-up 0.2s ease-out", "gentle-fade": "gentle-fade 0.3s ease-out" },
    fast: { "accordion-down": "accordion-down 0.1s ease-out", "accordion-up": "accordion-up 0.1s ease-out", "gentle-fade": "gentle-fade 0.15s ease-out" },
  };
  return speeds[speed] || speeds.normal;
}
EOF

# Update src/index.css – overwrite the :root variables and energy classes
cat > src/index.css << EOF
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 0 0% 3.9%;
    --card: 0 0% 100%;
    --card-foreground: 0 0% 3.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 0 0% 3.9%;
    --primary: 0 0% 9%;
    --primary-foreground: 0 0% 98%;
    --secondary: 0 0% 96.1%;
    --secondary-foreground: 0 0% 9%;
    --muted: 0 0% 96.1%;
    --muted-foreground: 0 0% 45.1%;
    --accent: 0 0% 96.1%;
    --accent-foreground: 0 0% 9%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 0 0% 98%;
    --border: 0 0% 89.8%;
    --input: 0 0% 89.8%;
    --ring: 0 0% 3.9%;
    --radius: 0.5rem;
    --energy-accent: $PRIMARY_COLOR;
  }

  .dark {
    --background: 0 0% 3.9%;
    --foreground: 0 0% 98%;
    --card: 0 0% 3.9%;
    --card-foreground: 0 0% 98%;
    --popover: 0 0% 3.9%;
    --popover-foreground: 0 0% 98%;
    --primary: 0 0% 98%;
    --primary-foreground: 0 0% 9%;
    --secondary: 0 0% 14.9%;
    --secondary-foreground: 0 0% 98%;
    --muted: 0 0% 14.9%;
    --muted-foreground: 0 0% 63.9%;
    --accent: 0 0% 14.9%;
    --accent-foreground: 0 0% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 0 0% 98%;
    --border: 0 0% 14.9%;
    --input: 0 0% 14.9%;
    --ring: 0 0% 83.1%;
  }

  .energy-warm { --energy-bg: #FDF6E3; --energy-text: #3E2C1F; --energy-accent: #C17B4C; }
  .energy-precise { --energy-bg: #F1F5F9; --energy-text: #0F172A; --energy-accent: $PRIMARY_COLOR; }
  .energy-playful { --energy-bg: #FFE2E2; --energy-text: #4A2E2E; --energy-accent: #F97316; }
  .energy-celebratory { --energy-bg: #FFF0D4; --energy-text: #5C3E1A; --energy-accent: #EAB308; }
  .energy-urgent { --energy-bg: #FFECE5; --energy-text: #9B2C1D; --energy-accent: #DC2626; }
  .energy-reflective { --energy-bg: #E6F0FA; --energy-text: #1E3A5F; --energy-accent: #3B82F6; }

  body { background-color: var(--energy-bg); color: var(--energy-text); font-family: theme('fontFamily.sans'); }
  .signature-focus-ring { outline: none; ring: $FOCUS_RING_WIDTH solid var(--energy-accent); ring-offset: $FOCUS_RING_OFFSET; }
}
EOF

# Update DesignEnergyContext.tsx to use the default energy from config
sed -i.bak "s/return 'precise';/return '$ENERGY_DEFAULT';/g" src/contexts/DesignEnergyContext.tsx
rm src/contexts/DesignEnergyContext.tsx.bak

echo '{"status":"success","changed":true,"summary":"Tailwind config and CSS regenerated from design.config.json"}'