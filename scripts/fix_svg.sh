#!/bin/bash

# Script to fix SVG files exported from Figma
# Usage: ./fix_svg.sh <path-to-svg-file>

SVG_FILE="$1"

if [ -z "$SVG_FILE" ]; then
    echo "Usage: ./fix_svg.sh <path-to-svg-file>"
    exit 1
fi

if [ ! -f "$SVG_FILE" ]; then
    echo "Error: File not found: $SVG_FILE"
    exit 1
fi

echo "Fixing SVG file: $SVG_FILE"

# Create backup
cp "$SVG_FILE" "$SVG_FILE.backup"

# Fix CSS variables: var(--fill-0, white) -> white
sed -i '' 's/fill="var(--fill-0, white)"/fill="white"/g' "$SVG_FILE"
sed -i '' 's/fill="var(--fill-1, white)"/fill="white"/g' "$SVG_FILE"
sed -i '' 's/fill="var(--fill-2, white)"/fill="white"/g' "$SVG_FILE"

# Fix stroke variables
sed -i '' 's/stroke="var(--stroke-0, white)"/stroke="white"/g' "$SVG_FILE"
sed -i '' 's/stroke="var(--stroke-1, white)"/stroke="white"/g' "$SVG_FILE"

# Remove style attribute if present
sed -i '' 's/ style="display: block;"//g' "$SVG_FILE"

# Check if file ends with </svg>
if ! tail -1 "$SVG_FILE" | grep -q '</svg>'; then
    echo "</svg>" >> "$SVG_FILE"
    echo "Added closing </svg> tag"
fi

# Validate basic SVG structure
if grep -q '<svg' "$SVG_FILE" && grep -q '</svg>' "$SVG_FILE"; then
    echo "✅ SVG file fixed successfully!"
else
    echo "❌ Error: Invalid SVG structure"
    mv "$SVG_FILE.backup" "$SVG_FILE"
    exit 1
fi

# Show file info
echo "File size: $(wc -c < "$SVG_FILE") bytes"
echo "Lines: $(wc -l < "$SVG_FILE")"

