#!/bin/bash

# Exit on error
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPONENTS_TARBALL="$SKILL_ROOT/assets/shadcn-components.tar.gz"

# Detect Node version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)

echo "🔍 Detected Node.js version: $NODE_VERSION"

if [ "$NODE_VERSION" -lt 18 ]; then
  echo "❌ Error: Node.js 18 or higher is required"
  echo "   Current version: $(node -v)"
  exit 1
fi

# Set Vite version based on Node version
if [ "$NODE_VERSION" -ge 20 ]; then
  VITE_VERSION="latest"
  echo "✅ Using Vite latest (Node 20+)"
else
  VITE_VERSION="5.4.11"
  echo "✅ Using Vite $VITE_VERSION (Node 18 compatible)"
fi

# Detect OS and set sed syntax
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE="sed -i ''"
else
  SED_INPLACE="sed -i"
fi

# Check if pnpm is installed
if ! command -v pnpm &> /dev/null; then
  echo "📦 pnpm not found. Installing pnpm..."
  npm install -g pnpm
fi

if [ -z "$1" ]; then
  echo "❌ Usage: ./init-artifact.sh <project-name>"
  exit 1
fi

PROJECT_NAME="$1"

if [ ! -f "$COMPONENTS_TARBALL" ]; then
  echo "❌ Error: shadcn-components.tar.gz not found at $COMPONENTS_TARBALL"
  exit 1
fi

echo "🚀 Creating new React + Vite project: $PROJECT_NAME"

pnpm create vite "$PROJECT_NAME" --template react-ts
cd "$PROJECT_NAME"

echo "🧹 Cleaning up Vite template..."
$SED_INPLACE '/<link rel="icon".*vite\.svg/d' index.html
$SED_INPLACE 's/<title>.*<\/title>/<title>'"$PROJECT_NAME"'<\/title>/' index.html

echo "📦 Installing base dependencies..."
pnpm install
pnpm add -D typescript@~5.8.3

if [ "$NODE_VERSION" -lt 20 ]; then
  echo "📌 Pinning Vite to $VITE_VERSION for Node 18 compatibility..."
  pnpm add -D vite@$VITE_VERSION
fi

echo "📦 Installing Tailwind CSS and dependencies..."
pnpm install -D tailwindcss@3.4.1 postcss autoprefixer @types/node tailwindcss-animate
pnpm install class-variance-authority clsx tailwind-merge lucide-react next-themes

# --- Tailwind configuration with design skill tokens ---
cat > postcss.config.js << 'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

cat > tailwind.config.js << 'EOF'
import animate from "tailwindcss-animate";

/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ["class"],
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
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
        // --- Custom design skill energies ---
        energy: {
          warm: "#FDF6E3",
          precise: "#F1F5F9",
          playful: "#FFE2E2",
          celebratory: "#FFF0D4",
          urgent: "#FFECE5",
          reflective: "#E6F0FA",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
        "gentle-fade": {
          "0%": { opacity: "0", transform: "translateY(4px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        "gentle-fade": "gentle-fade 0.3s ease-out",
      },
    },
  },
  plugins: [animate],
}
EOF

# --- CSS variables and design skill foundations ---
cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    /* Neutral base (light mode) */
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
    --muted-foreground: 0 0% 32%;
    --accent: 0 0% 96.1%;
    --accent-foreground: 0 0% 9%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 0 0% 98%;
    --border: 0 0% 89.8%;
    --input: 0 0% 89.8%;
    --ring: 0 0% 3.9%;
    --radius: 0.5rem;

    /* Design skill: energy overrides (default = precise/professional) */
    --energy-bg: var(--background);
    --energy-text: var(--foreground);
    --energy-accent: var(--primary);
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

  /* Energy classes (applied to body or container) */
  .energy-warm {
    --energy-bg: #FDF6E3;
    --energy-text: #3E2C1F;
    --energy-accent: #C17B4C;
  }
  .energy-precise {
    --energy-bg: #F1F5F9;
    --energy-text: #0F172A;
    --energy-accent: #2563EB;
  }
  .energy-playful {
    --energy-bg: #FFE2E2;
    --energy-text: #4A2E2E;
    --energy-accent: #F97316;
  }
  .energy-celebratory {
    --energy-bg: #FFF0D4;
    --energy-text: #5C3E1A;
    --energy-accent: #EAB308;
  }
  .energy-urgent {
    --energy-bg: #FFECE5;
    --energy-text: #9B2C1D;
    --energy-accent: #DC2626;
  }
  .energy-reflective {
    --energy-bg: #E6F0FA;
    --energy-text: #1E3A5F;
    --energy-accent: #3B82F6;
  }

  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
    background-color: var(--energy-bg);
    color: var(--energy-text);
  }
  ::selection {
    background-color: var(--energy-accent);
    color: white;
  }
}

@layer components {
  .signature-focus-ring {
    outline: none;
    box-shadow: 0 0 0 2px var(--background), 0 0 0 4px var(--energy-accent);
  }
  .card-editorial {
    @apply bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm rounded-lg shadow-sm border border-border p-6 transition-all duration-200;
  }
}
EOF

# --- Path aliases ---
node -e "
const fs = require('fs');
const config = JSON.parse(fs.readFileSync('tsconfig.json', 'utf8'));
config.compilerOptions = config.compilerOptions || {};
config.compilerOptions.verbatimModuleSyntax = false;
config.compilerOptions.baseUrl = '.';
config.compilerOptions.paths = { '@/*': ['./src/*'] };
fs.writeFileSync('tsconfig.json', JSON.stringify(config, null, 2));
"

node -e "
const fs = require('fs');
const path = 'tsconfig.app.json';
if (fs.existsSync(path)) {
  let content = fs.readFileSync(path, 'utf8');
  content = content.replace(/\\/\\/.*|\\/\\*[\\s\\S]*?\\*\\//g, '');
  const config = JSON.parse(content);
  config.compilerOptions = config.compilerOptions || {};
  config.compilerOptions.verbatimModuleSyntax = false;
  config.compilerOptions.baseUrl = '.';
  config.compilerOptions.paths = { '@/*': ['./src/*'] };
  fs.writeFileSync(path, JSON.stringify(config, null, 2));
}
"

cat > vite.config.ts << 'EOF'
import path from "path";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
EOF

# --- Install all shadcn/ui & premium deps ---
pnpm install @radix-ui/react-accordion @radix-ui/react-aspect-ratio @radix-ui/react-avatar @radix-ui/react-checkbox @radix-ui/react-collapsible @radix-ui/react-context-menu @radix-ui/react-dialog @radix-ui/react-dropdown-menu @radix-ui/react-hover-card @radix-ui/react-label @radix-ui/react-menubar @radix-ui/react-navigation-menu @radix-ui/react-popover @radix-ui/react-progress @radix-ui/react-radio-group @radix-ui/react-scroll-area @radix-ui/react-select @radix-ui/react-separator @radix-ui/react-slider @radix-ui/react-slot @radix-ui/react-switch @radix-ui/react-tabs @radix-ui/react-toast @radix-ui/react-toggle @radix-ui/react-toggle-group @radix-ui/react-tooltip
pnpm install sonner cmdk vaul embla-carousel-react react-day-picker@9.11.3 react-resizable-panels@2.1.9 date-fns react-hook-form @hookform/resolvers zod
pnpm install zustand recharts@2.15.4 framer-motion @tanstack/react-query react-router-dom

# --- Extract shadcn components ---
mkdir -p src/components/ui
tar -xzf "$COMPONENTS_TARBALL" -C src/

# --- Additional design skill custom components & pages ---
mkdir -p src/lib src/hooks src/components/design-skills src/pages src/contexts

# Design rationale helper
cat > src/lib/design-utils.ts << 'EOF'
export type DesignEnergy = 
  | 'warm' | 'precise' | 'playful' | 'celebratory' | 'urgent' | 'reflective';

export interface DesignRationale {
  vibe: string;
  translation: string;
  constraints: string[];
}

export function logRationale(rationale: DesignRationale) {
  console.group('🎨 Design Rationale');
  console.log('Vibe:', rationale.vibe);
  console.log('Translation:', rationale.translation);
  console.log('Constraints:', rationale.constraints.join(', '));
  console.groupEnd();
}
EOF

# Signature Detail: motion wrapper that respects reduced-motion
cat > src/components/design-skills/MotionWrapper.tsx << 'EOF'
import { motion, MotionProps } from 'framer-motion';
import { useEffect, useState } from 'react';

export function MotionWrapper({ children, ...props }: MotionProps & { children: React.ReactNode }) {
  const [prefersReduced, setPrefersReduced] = useState(false);

  useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReduced(mediaQuery.matches);
    const handler = (e: MediaQueryListEvent) => setPrefersReduced(e.matches);
    mediaQuery.addEventListener('change', handler);
    return () => mediaQuery.removeEventListener('change', handler);
  }, []);

  if (prefersReduced) {
    return <>{children}</>;
  }
  return <motion.div {...props}>{children}</motion.div>;
}
EOF

# Energy context provider
cat > src/contexts/DesignEnergyContext.tsx << 'EOF'
import { createContext, useContext, useState, ReactNode } from 'react';
import { DesignEnergy } from '@/lib/design-utils';

type EnergyContextType = {
  energy: DesignEnergy;
  setEnergy: (energy: DesignEnergy) => void;
};

const EnergyContext = createContext<EnergyContextType | undefined>(undefined);

export function DesignEnergyProvider({ children }: { children: ReactNode }) {
  const [energy, setEnergy] = useState<DesignEnergy>('precise');

  return (
    <EnergyContext.Provider value={{ energy, setEnergy }}>
      <div className={`energy-${energy}`}>
        {children}
      </div>
    </EnergyContext.Provider>
  );
}

export function useDesignEnergy() {
  const ctx = useContext(EnergyContext);
  if (!ctx) throw new Error('useDesignEnergy must be used within DesignEnergyProvider');
  return ctx;
}
EOF

# Example: Wedding Timeline page (Ash2026)
cat > src/pages/WeddingTimeline.tsx << 'EOF'
import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Heart, Camera, Send } from 'lucide-react';
import { MotionWrapper } from '@/components/design-skills/MotionWrapper';
import { logRationale } from '@/lib/design-utils';

export function WeddingTimeline() {
  const [posts, setPosts] = useState([
    { id: 1, user: 'Emma & Liam', text: 'The vows were magical!', likes: 12 },
    { id: 2, user: 'Aunt Sarah', text: 'Such a beautiful ceremony 💒', likes: 8 },
  ]);
  const [newPost, setNewPost] = useState('');

  // Design rationale embedded right in the component
  logRationale({
    vibe: 'private wedding social timeline for mixed-age guests at a live event',
    translation: 'warm editorial memory-book surface, familiar social post layout, clear camera/gallery actions, soft wedding accents',
    constraints: ['mobile-first', 'large tap targets', 'no autoplay video', 'compressed media', 'clear upload states', 'readable in crowded event conditions']
  });

  const addPost = () => {
    if (!newPost.trim()) return;
    setPosts([{ id: Date.now(), user: 'You', text: newPost, likes: 0 }, ...posts]);
    setNewPost('');
  };

  return (
    <div className="max-w-2xl mx-auto p-4 space-y-6">
      <MotionWrapper initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.4 }}>
        <h1 className="text-3xl font-serif text-energy-accent">💍 Ash & Alex · 2026</h1>
        <p className="text-foreground">Share your memories from our special day</p>
      </MotionWrapper>

      <Card className="border-energy-accent/20 shadow-md">
        <CardContent className="pt-4 space-y-3">
          <textarea
            className="w-full p-3 border rounded-lg resize-none focus:ring-2 focus:ring-energy-accent outline-none"
            rows={3}
            placeholder="Write your wish for the newlyweds..."
            value={newPost}
            onChange={(e) => setNewPost(e.target.value)}
          />
          <div className="flex gap-2 justify-end">
            <Button variant="outline" size="sm"><Camera className="w-4 h-4 mr-2" /> Photo</Button>
            <Button onClick={addPost} size="sm"><Send className="w-4 h-4 mr-2" /> Post</Button>
          </div>
        </CardContent>
      </Card>

      <div className="space-y-4">
        {posts.map((post) => (
          <MotionWrapper key={post.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.2 }}>
            <Card>
              <CardContent className="pt-4">
                <div className="flex items-start gap-3">
                  <Avatar><AvatarFallback>{post.user[0]}</AvatarFallback></Avatar>
                  <div className="flex-1">
                    <p className="font-semibold">{post.user}</p>
                    <p className="text-sm text-muted-foreground mt-1">{post.text}</p>
                    <button className="flex items-center gap-1 text-sm text-muted-foreground hover:text-red-500 mt-2 transition-colors">
                      <Heart className="w-4 h-4" /> {post.likes}
                    </button>
                  </div>
                </div>
              </CardContent>
            </Card>
          </MotionWrapper>
        ))}
      </div>
    </div>
  );
}
EOF

# Replace default App.tsx with a design skill showcase
cat > src/App.tsx << 'EOF'
import { DesignEnergyProvider, useDesignEnergy } from '@/contexts/DesignEnergyContext';
import { WeddingTimeline } from '@/pages/WeddingTimeline';

function EnergySelector() {
  const { energy, setEnergy } = useDesignEnergy();
  const energies = ['warm', 'precise', 'playful', 'celebratory', 'urgent', 'reflective'] as const;
  return (
    <div className="fixed bottom-4 right-4 z-50 bg-background/80 backdrop-blur-sm p-2 rounded-full shadow-lg border">
      <select
        aria-label="Design energy"
        value={energy}
        onChange={(e) => setEnergy(e.target.value as any)}
        className="bg-transparent text-sm font-mono px-2 py-1 rounded-full focus:outline-none focus:ring-2 focus:ring-ring"
      >
        {energies.map(e => <option key={e}>{e}</option>)}
      </select>
    </div>
  );
}

function AppContent() {
  return (
    <main className="min-h-screen transition-colors duration-300">
      <WeddingTimeline />
      <EnergySelector />
    </main>
  );
}

export default function App() {
  return (
    <DesignEnergyProvider>
      <AppContent />
    </DesignEnergyProvider>
  );
}
EOF

# Create components.json for shadcn
cat > components.json << 'EOF'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.js",
    "css": "src/index.css",
    "baseColor": "slate",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  }
}
EOF

# Add design guidelines documentation
cat > DESIGN_GUIDELINES.md << 'EOF'
# Frontend Design Skill – Context‑Adaptive Interface Direction

This project follows the principles from `arh-frontend-design-skill-HLD-v1.md`.

## Core Principles
- Design is translation: content → structure, audience → clarity, energy → tone.
- Never start from a visual trend. Start from the situation.

## Available Energies
| Energy        | Use Case                              | Palette                      |
|---------------|---------------------------------------|------------------------------|
| `warm`        | Human memory, personal storytelling   | Soft neutral, natural        |
| `precise`     | Dashboards, technical control         | Restrained, high clarity     |
| `playful`     | Games, creative tools                 | Expressive, responsive       |
| `celebratory` | Events, achievements                  | Richer accents, generous     |
| `urgent`      | Action‑heavy, high‑stakes tasks       | Bold affordances, fewer choices |
| `reflective`  | Long‑form reading, portfolios         | Slow rhythm, editorial       |

## Accessibility Floor (WCAG 2.2)
- Minimum contrast 4.5:1
- Visible focus states (`.signature-focus-ring`)
- Reduced‑motion support (`MotionWrapper`)
- Keyboard reachable, touch targets ≥44px

## Performance Floor
- Lazy‑load images, no autoplay video
- First screen < 200kB JS (Vite optimises)
- Show loading/error states for every async action

## How to Apply
1. Identify the **human situation** (audience, energy, device).
2. Choose an energy class and embed rationale with `logRationale()`.
3. Use `MotionWrapper` only for meaningful transitions (not decoration).
4. Respect the signature detail – every page should have one interaction that belongs to the content.

## Additional Sources
- [NN/g Visual Design Principles](https://media.nngroup.com/media/articles/attachments/Principles_Visual_Design-Letter.pdf)
- [Material Design (M1)](https://m1.material.io/)
- [WCAG 2.2](https://www.w3.org/TR/WCAG22/)
- [Apple Typography HIG](https://developer.apple.com/design/human-interface-guidelines/typography)
EOF

# Final verification
echo "🔍 Verifying installation..."
MISSING=0
for file in "src/lib/utils.ts" "src/components/ui/button.tsx" "src/index.css"; do
  if [ ! -f "$file" ]; then
    echo "  ❌ Missing: $file"
    MISSING=1
  fi
done

if [ "$MISSING" -eq 0 ]; then
  echo "✅ All key components verified"
else
  echo "⚠️ Some components missing – check tarball"
fi

echo ""
echo "✅ Frontend Design Skill enabled project created: $PROJECT_NAME"
echo ""
echo "📦 Includes:"
echo "  - shadcn/ui components + custom design skill components"
echo "  - WeddingTimeline page (Ash2026 example)"
echo "  - Energy context & motion wrapper"
echo "  - DESIGN_GUIDELINES.md with full philosophy"
echo ""
echo "🚀 Start developing:"
echo "  cd $PROJECT_NAME"
echo "  pnpm dev"
echo ""
echo "✨ Switch energies live with the floating selector."
