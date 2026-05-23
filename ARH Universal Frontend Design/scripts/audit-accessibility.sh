#!/bin/bash
set -e
echo "♿ Running accessibility audit with axe-core..."
PORT="${PORT:-5173}"

if ! command -v npx &> /dev/null; then
  echo "❌ npx not found"
  exit 1
fi

# Start dev server in background
pnpm exec vite --host 127.0.0.1 --port "$PORT" --strictPort &
SERVER_PID=$!
cleanup() {
  rm -f audit.mjs
  kill "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT
sleep 5  # wait for server to start
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "❌ Vite dev server failed to start on port $PORT"
  exit 1
fi

# Run axe-core via @axe-core/playwright
pnpm add -D playwright @playwright/test @axe-core/playwright
npx playwright install chromium
cat > audit.mjs << 'EOF'
import { chromium } from 'playwright';
import AxeBuilder from '@axe-core/playwright';

(async () => {
  const browser = await chromium.launch();
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto('http://127.0.0.1:' + process.env.PORT);
  
  const results = await new AxeBuilder({ page }).analyze();
  console.log(`Violations found: ${results.violations.length}`);
  if (results.violations.length > 0) {
    console.log(JSON.stringify(results.violations, null, 2));
    process.exit(1);
  }
  console.log('✅ No accessibility violations detected.');
  await context.close();
  await browser.close();
})();
EOF

PORT="$PORT" node audit.mjs
echo "🏁 Accessibility audit finished."
