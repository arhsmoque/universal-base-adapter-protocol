#!/bin/bash
set -e

SCALE="$1"
if [[ ! "$SCALE" =~ ^(compact|comfortable|spacious)$ ]]; then
  echo '{"status":"error","summary":"Invalid scale. Use compact, comfortable, or spacious"}'
  exit 1
fi

DRY_RUN=false
if [ "$2" == "--dry-run" ]; then
  DRY_RUN=true
fi

CONFIG_FILE="design.config.json"
if [ ! -f "$CONFIG_FILE" ]; then
  echo '{"status":"error","summary":"design.config.json not found"}'
  exit 1
fi

# Update the JSON (using jq if available, else sed)
if command -v jq &> /dev/null; then
  if [ "$DRY_RUN" = true ]; then
    echo "{\"status\":\"dry_run\",\"summary\":\"Would set spacing scale to $SCALE\"}"
    exit 0
  fi
  jq --arg scale "$SCALE" '.designTokens.spacingScale = $scale' "$CONFIG_FILE" > tmp.$$.json && mv tmp.$$.json "$CONFIG_FILE"
else
  # fallback: sed (dangerous, but works for simple string)
  if [ "$DRY_RUN" = true ]; then
    echo '{"status":"dry_run","summary":"Would attempt to set spacing scale (no jq, partial reliability)"}'
    exit 0
  fi
  sed -i.bak "s/\"spacingScale\": \".*\"/\"spacingScale\": \"$SCALE\"/" "$CONFIG_FILE"
  rm "$CONFIG_FILE.bak"
fi

# Regenerate configs
./generate-tailwind-config.sh

echo "{\"status\":\"success\",\"changed\":true,\"summary\":\"Spacing scale set to $SCALE\",\"next_action_hint\":\"Run pnpm dev to preview\"}"