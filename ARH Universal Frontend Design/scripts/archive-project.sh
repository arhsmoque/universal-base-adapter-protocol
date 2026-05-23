#!/bin/bash
set -e
echo "📦 Creating downloadable archive of the project..."

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ARCHIVE_NAME="${PWD##*/}-${TIMESTAMP}.tar.gz"

# Exclude node_modules, .git, dist, bundle.html, etc.
tar --exclude="node_modules" \
    --exclude=".git" \
    --exclude="dist" \
    --exclude="bundle.html" \
    --exclude="*.log" \
    -czf "../$ARCHIVE_NAME" .

echo "✅ Archive created: ../$ARCHIVE_NAME"
echo "   Size: $(du -h "../$ARCHIVE_NAME" | cut -f1)"
echo "🎉 You can now download and share this archive."