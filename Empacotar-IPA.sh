#!/bin/bash
set -euo pipefail

ROOT="${SRCROOT:-$(pwd)}"
BUILD_ROOT="${BUILD_ROOT:-$ROOT/build}"

# Search common Xcode output folders, preferring the requested External.app,
# then the project's configured product name (3105.app).
APP_PATH=""
for candidate in \
  "$BUILD_ROOT/Release-iphoneos/External.app" \
  "$BUILD_ROOT/DerivedData/Build/Products/Release-iphoneos/External.app" \
  "$BUILD_ROOT/Release-iphoneos/3105.app" \
  "$BUILD_ROOT/DerivedData/Build/Products/Release-iphoneos/3105.app"; do
  if [ -d "$candidate" ]; then APP_PATH="$candidate"; break; fi
done

if [ -z "$APP_PATH" ]; then
  APP_PATH="$(find "$BUILD_ROOT" -type d \( -name 'External.app' -o -name '3105.app' \) -print -quit 2>/dev/null || true)"
fi

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
  echo "ERRO: nenhum .app foi encontrado em $BUILD_ROOT. Verifique se a etapa xcodebuild terminou com sucesso."
  echo "Produtos .app encontrados (se houver):"
  find "$BUILD_ROOT" -type d -name '*.app' -print 2>/dev/null || true
  exit 1
fi

OUT_DIR="$ROOT/build/ipa-payload"
mkdir -p "$OUT_DIR/Payload"
rm -rf "$OUT_DIR/Payload/"*.app
cp -R "$APP_PATH" "$OUT_DIR/Payload/"
mkdir -p "$ROOT/build"
(cd "$OUT_DIR" && /usr/bin/zip -qr "$ROOT/build/External.ipa" Payload)
echo "IPA criado: $ROOT/build/External.ipa"
