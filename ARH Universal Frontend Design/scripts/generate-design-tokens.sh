#!/bin/bash
set -e
echo "🎨 Generating design tokens from Tailwind config..."

if [ ! -f "tailwind.config.js" ]; then
  echo "❌ No tailwind.config.js found. Run init-artifact.sh first."
  exit 1
fi

# Use a tiny Node script to extract colors, spacing, etc.
node << 'NODE_SCRIPT'
const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');

async function main() {
  const tailwindConfigPath = path.resolve('./tailwind.config.js');
  if (!fs.existsSync(tailwindConfigPath)) {
    console.error('Cannot find tailwind.config.js.');
    process.exit(1);
  }

  const module = await import(pathToFileURL(tailwindConfigPath).href);
  const config = module.default || module;

  const theme = config.theme?.extend || {};
  const tokens = {
    colors: theme.colors || {},
    spacing: theme.spacing || {},
    borderRadius: theme.borderRadius || {},
    fontFamily: theme.fontFamily || {},
    animation: theme.animation || {},
  };

  // Write JSON for cross-platform use
  fs.writeFileSync('./design-tokens.json', JSON.stringify(tokens, null, 2));

  // Write CSS custom properties (optional)
  let cssVars = ':root {\n';
  Object.entries(tokens.colors).forEach(([name, value]) => {
    if (typeof value === 'string') cssVars += `  --color-${name}: ${value};\n`;
  });
  cssVars += '}\n';
  fs.writeFileSync('./design-tokens.css', cssVars);
  console.log('✅ design-tokens.json and design-tokens.css created');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
NODE_SCRIPT

echo "✨ Design tokens extracted. You can now use them in Figma, mobile apps, or documentation."
