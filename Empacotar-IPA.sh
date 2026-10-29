#!/bin/bash
set -euo pipefail

# Empacota o .app gerado pelo Xcode sem assumir que o produto se chama External.app.
ROOT="${SRCROOT:-$(pwd)}"
BUILD_ROOT="${BUILD_ROOT:-$ROOT/build}"
PRODUCT_NAME="${FULL_PRODUCT_NAME:-}"

# Use os caminhos fornecidos pelo Xcode quando o script roda como Build Phase.
CANDIDATES=()
if [[ -n "${TARGET_BUILD_DIR:-}" && -n "$PRODUCT_NAME" ]]; then
  CANDIDATES+=("$TARGET_BUILD_DIR/$PRODUCT_NAME")
fi
if [[ -n "${BUILT_PRODUCTS_DIR:-}" && -n "$PRODUCT_NAME" ]]; then
  CANDIDATES+=("$BUILT_PRODUCTS_DIR/$PRODUCT_NAME")
fi
CANDIDATES+=(
  "$BUILD_ROOT/Release-iphoneos/External.app"
  "$BUILD_ROOT/Release-iphoneos/3105.app"
  "$BUILD_ROOT/DerivedData/Build/Products/Release-iphoneos/External.app"
  "$BUILD_ROOT/DerivedData/Build/Products/Release-iphoneos/3105.app"
  "$ROOT/Build/Products/Release-iphoneos/External.app"
  "$ROOT/Build/Products/Release-iphoneos/3105.app"
)

APP_PATH=""
for candidate in "${CANDIDATES[@]}"; do
  if [[ -d "$candidate" ]]; then APP_PATH="$candidate"; break; fi
done

# Busca também em diretórios usuais de build/DerivedData, sem falhar se algum não existir.
if [[ -z "$APP_PATH" ]]; then
  for search_root in "$BUILD_ROOT" "$ROOT/build" "$ROOT/DerivedData" "$ROOT"; do
    [[ -d "$search_root" ]] || continue
    APP_PATH="$(find "$search_root" -type d \( -name 'External.app' -o -name '3105.app' \) -print -quit 2>/dev/null || true)"
    [[ -n "$APP_PATH" ]] && break
  done
fi

if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "ERRO: nenhum .app foi encontrado. A compilação do Xcode pode ter falhado ou o diretório de build é diferente."
  echo "SRCROOT=${SRCROOT:-não definido}"
  echo "BUILD_ROOT=$BUILD_ROOT"
  echo "TARGET_BUILD_DIR=${TARGET_BUILD_DIR:-não definido}"
  echo "BUILT_PRODUCTS_DIR=${BUILT_PRODUCTS_DIR:-não definido}"
  echo "FULL_PRODUCT_NAME=${FULL_PRODUCT_NAME:-não definido}"
  echo "Procurando arquivos .app em diretórios comuns:"
  for search_root in "$BUILD_ROOT" "$ROOT/DerivedData" "$ROOT"; do
    [[ -d "$search_root" ]] && find "$search_root" -type d -name '*.app' -print 2>/dev/null || true
  done
  exit 1
fi

echo "Aplicativo encontrado: $APP_PATH"
OUT_DIR="$ROOT/build/ipa-payload"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR/Payload"
cp -R "$APP_PATH" "$OUT_DIR/Payload/"
mkdir -p "$ROOT/build"
(cd "$OUT_DIR" && /usr/bin/zip -qr "$ROOT/build/External.ipa" Payload)
echo "IPA criado: $ROOT/build/External.ipa"
