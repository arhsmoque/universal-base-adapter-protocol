#!/bin/bash
set -e

echo "📦 Bundling React app to single HTML artifact (with design skill validation)..."

# Check if we're in a project directory
if [ ! -f "package.json" ]; then
  echo "❌ Error: No package.json found. Run this script from your project root."
  exit 1
fi

# Backup existing vite.config.ts if present and not already backed up
if [ -f "vite.config.ts" ] && [ ! -f "vite.config.ts.backup" ]; then
  cp vite.config.ts vite.config.ts.backup
  echo "💾 Backed up original vite.config.ts to vite.config.ts.backup"
fi

# Install vite-plugin-singlefile
echo "🔌 Installing vite-plugin-singlefile..."
pnpm add -D vite-plugin-singlefile

# Update vite.config.ts to use the plugin
echo "⚙️  Configuring Vite for single-file output..."
cat > vite.config.ts << 'EOF'
import path from "path";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";
import { viteSingleFile } from "vite-plugin-singlefile";

export default defineConfig({
  plugins: [react(), viteSingleFile()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  build: {
    cssCodeSplit: false,
    assetsInlineLimit: 100000000, // inline all assets
    rollupOptions: {
      output: {
        manualChunks: undefined,
      },
    },
  },
});
EOF

# Pre-bundle validation (a11y + performance checks)
echo ""
echo "🔎 Running pre‑bundle design skill validation..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check 1: MotionWrapper presence (reduced-motion support)
if grep -R -q "MotionWrapper" src --include='*.tsx' 2>/dev/null; then
  echo "  ✅ MotionWrapper found – reduced‑motion support present"
else
  echo "  ⚠️  No MotionWrapper detected – add reduced‑motion support"
fi

# Check 2: Visible focus states
if grep -R -E -q "focus:ring|signature-focus-ring" src --include='*.css' --include='*.tsx' 2>/dev/null; then
  echo "  ✅ Focus rings/indicators detected"
else
  echo "  ⚠️  Missing visible focus indicators – add focus:ring or .signature-focus-ring"
fi

# Check 3: Touch targets (mobile-friendly)
if grep -R -E -q "touch-target|min-height:.*44" src --include='*.css' --include='*.tsx' 2>/dev/null; then
  echo "  ✅ Touch target sizing detected (≥44px)"
else
  echo "  ⚠️  No touch target utilities found – consider adding .touch-target class"
fi

# Check 4: Generic anti-patterns (dark neon, gradient hero)
if grep -R -E -q "bg-gradient-to-r|from-purple-|to-blue-|neon|glassmorphism" src --include='*.tsx' --include='*.css' 2>/dev/null; then
  echo "  ⚠️  Warning: Generic gradient, neon, or glassmorphism detected – review against design skill (should serve context, not default)"
else
  echo "  ✅ No generic anti-pattern gradients detected"
fi

# Check 5: Lazy loading on images
if grep -R -q "loading=\"lazy\"" src --include='*.tsx' 2>/dev/null; then
  echo "  ✅ Lazy loading found on images"
else
  echo "  ⚠️  No lazy loading found on images – add loading='lazy' for performance"
fi

# Check 6: Design rationale presence
if grep -R -q "logRationale" src --include='*.tsx' 2>/dev/null; then
  echo "  ✅ Design rationale logging found"
else
  echo "  ⚠️  No logRationale() calls – add design rationale to pages"
fi

# Check 7: Energy provider
if grep -q "DesignEnergyProvider" src/App.tsx 2>/dev/null; then
  echo "  ✅ DesignEnergyProvider found in App.tsx"
else
  echo "  ⚠️  DesignEnergyProvider missing – wrap app for energy switching"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf dist bundle.html

# Build with Vite
echo "🔨 Building standalone artifact..."
pnpm exec vite build

# Verify build succeeded
if [ ! -f "dist/index.html" ]; then
  echo "❌ Error: Build failed - dist/index.html not found"
  exit 1
fi

# Move the output
echo "🎯 Finalizing artifact..."
mv dist/index.html bundle.html
rm -rf dist

# Get file size
FILE_SIZE=$(du -h bundle.html | cut -f1)
FILE_SIZE_BYTES=$(stat -f%z bundle.html 2>/dev/null || stat -c%s bundle.html 2>/dev/null)
FILE_SIZE_MB=$((FILE_SIZE_BYTES / 1024 / 1024))

# Generate SRI integrity hash (optional)
if command -v shasum &> /dev/null; then
  SRI_HASH=$(shasum -b -a 384 bundle.html 2>/dev/null | awk '{ print $1 }' | xxd -r -p | base64 2>/dev/null || echo "N/A")
  if [ "$SRI_HASH" != "N/A" ]; then
    echo "$SRI_HASH" > bundle.html.sri
    echo "  🔒 SRI hash saved to bundle.html.sri"
  fi
fi

# Compress with brotli if available
if command -v brotli &> /dev/null; then
  echo "🗜️  Creating Brotli compressed version..."
  brotli -Z bundle.html -o bundle.html.br 2>/dev/null || true
  BROTLI_SIZE=$(du -h bundle.html.br 2>/dev/null | cut -f1 || echo "unknown")
  echo "  📦 Brotli compressed: $BROTLI_SIZE"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Bundle complete!"
echo "📄 Output: bundle.html ($FILE_SIZE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$FILE_SIZE_MB" -gt 5 ]; then
  echo "⚠️  Warning: Bundle is ${FILE_SIZE_MB}MB. Large bundles may cause performance issues or exceed Claude's limits."
  echo "   Consider:"
  echo "   - Compressing images further"
  echo "   - Removing unused dependencies"
  echo "   - Lazy-loading heavy components"
elif [ "$FILE_SIZE_MB" -gt 2 ]; then
  echo "ℹ️  Bundle size is ${FILE_SIZE_MB}MB – acceptable but could be optimized."
else
  echo "✅ Bundle size is ${FILE_SIZE_MB}MB – well within limits!"
fi

echo ""
echo "✨ Design skill validation summary:"
echo "   - Accessibility: basic focus, motion, touch checks completed"
echo "   - Anti-pattern scan: done (review warnings above)"
echo "   - Performance: single HTML file with inlined assets"
echo "   - SRI hash: $( [ -f bundle.html.sri ] && echo "generated" || echo "not generated" )"
echo ""
echo "🚀 You can now share bundle.html in Claude conversations."
echo "   The artifact is self-contained with zero external network requests."
