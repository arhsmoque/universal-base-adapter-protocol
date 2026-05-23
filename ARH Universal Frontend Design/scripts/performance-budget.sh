#!/bin/bash
set -e
echo "📊 Running performance budget analysis..."

# Install visualizer if not present
pnpm add -D rollup-plugin-visualizer

# Build with bundle visualizer
cat > vite.config.analyze.ts << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig({
  plugins: [
    react(),
    visualizer({
      filename: 'dist/stats.json',
      template: 'raw-data',
      gzipSize: true,
      brotliSize: true
    })
  ],
  build: { rollupOptions: { output: { manualChunks: undefined } } }
});
EOF

pnpm exec vite build --config vite.config.analyze.ts

# Extract total bundle size from stats.json
if [ -f "dist/stats.json" ]; then
  SIZE=$(node -e "const fs=require('fs'); const path=require('path'); const dir='dist/assets'; const total=fs.existsSync(dir) ? fs.readdirSync(dir).filter(f=>/\\.(js|css)$/.test(f)).reduce((sum,f)=>sum+fs.statSync(path.join(dir,f)).size,0) : 0; console.log(Math.round(total/1024))")
  echo "Total bundle size: ${SIZE} KB"
  if [ "$SIZE" -gt 500 ]; then
    echo "⚠️ Budget exceeded! (limit 500 KB for first load)"
    exit 1
  else
    echo "✅ Size within budget (500 KB)"
  fi
else
  echo "⚠️ Could not measure precisely. Install rollup-plugin-visualizer and rebuild."
fi

rm -f vite.config.analyze.ts
echo "📈 Bundle statistics written to dist/stats.json."
