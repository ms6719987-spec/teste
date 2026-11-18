#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$ROOT/export_options.plist"
TARGET="/Users/builder/export_options.plist"
if [ ! -f "$SOURCE" ]; then
  echo "ERRO: arquivo ausente: $SOURCE" >&2
  exit 1
fi
mkdir -p "$(dirname "$TARGET")"
cp "$SOURCE" "$TARGET"
plutil -lint "$TARGET"
echo "Export options preparado em $TARGET"
