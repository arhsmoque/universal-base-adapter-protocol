#!/bin/bash
set -e
echo "📖 Setting up Storybook with design skill addons..."

if [ ! -f "package.json" ]; then
  echo "❌ Run this from your project root (after init-artifact.sh)"
  exit 1
fi

# Install Storybook and supported addons without invoking the interactive
# initializer, which can add transient addons and emit non-blocking setup errors.
pnpm add -D storybook @storybook/react-vite @storybook/addon-a11y @storybook/addon-docs @storybook/addon-themes --config.dangerously-allow-all-builds=true

node << 'EOF'
const fs = require('node:fs');
const packageJsonPath = 'package.json';
const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
packageJson.scripts = {
  ...packageJson.scripts,
  storybook: packageJson.scripts?.storybook || 'storybook dev -p 6006',
  'build-storybook': packageJson.scripts?.['build-storybook'] || 'storybook build'
};
fs.writeFileSync(packageJsonPath, `${JSON.stringify(packageJson, null, 2)}\n`);
EOF

mkdir -p .storybook

# Create a preview-head.html that injects design energy CSS
cat > .storybook/preview-head.html << 'EOF'
<style>
  /* Import your design energies from src/index.css */
  .energy-warm { --energy-bg: #FDF6E3; --energy-text: #3E2C1F; --energy-accent: #C17B4C; }
  .energy-precise { --energy-bg: #F1F5F9; --energy-text: #0F172A; --energy-accent: #2563EB; }
  .energy-playful { --energy-bg: #FFE2E2; --energy-text: #4A2E2E; --energy-accent: #F97316; }
  /* ... include all six energies from src/index.css */
  body { background-color: var(--energy-bg); color: var(--energy-text); }
</style>
EOF

# Configure Storybook to use Tailwind and expose design energies
cat > .storybook/main.ts << 'EOF'
import type { StorybookConfig } from '@storybook/react-vite';

const config: StorybookConfig = {
  stories: ['../src/**/*.stories.@(js|jsx|mjs|ts|tsx)'],
  addons: ['@storybook/addon-docs', '@storybook/addon-a11y', '@storybook/addon-themes'],
  framework: '@storybook/react-vite',
  core: {
    disableTelemetry: true
  }
};

export default config;
EOF

cat > .storybook/preview.tsx << 'EOF'
import type { Preview } from '@storybook/react';
import '../src/index.css';

const preview: Preview = {
  parameters: {
    controls: { expanded: true },
    a11y: {
      config: { rules: [{ id: 'color-contrast', enabled: true }] }
    }
  },
  decorators: [(Story, context) => {
    const energy = context.globals.energy || 'precise';
    document.body.className = `energy-${energy}`;
    return Story();
  }],
  globalTypes: {
    energy: {
      name: 'Design Energy',
      description: 'Switch design mood',
      defaultValue: 'precise',
      toolbar: {
        icon: 'paintbrush',
        items: ['warm', 'precise', 'playful', 'celebratory', 'urgent', 'reflective']
      }
    }
  }
};
export default preview;
EOF

if [ -f "src/App.tsx" ] && [ ! -f "src/App.stories.tsx" ]; then
cat > src/App.stories.tsx << 'EOF'
import type { Meta, StoryObj } from '@storybook/react-vite';
import App from './App';

const meta = {
  title: 'App/Frontend Design HLD',
  component: App,
  parameters: {
    layout: 'fullscreen'
  }
} satisfies Meta<typeof App>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};
EOF
fi

echo "✅ Storybook configured. Run 'pnpm storybook' to start."
