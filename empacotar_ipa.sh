#!/usr/bin/env bash
set -euo pipefail
ROOT="${CM_BUILD_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${CM_EXPORT_DIR:-$ROOT/output}"
mkdir -p "$OUT"
# Prefer the archived application; otherwise locate a compiled Release iPhoneOS application.
APP=""
while IFS= read -r -d '' candidate; do
  case "$candidate" in
    */Products/Applications/*.app|*/Release-iphoneos/*.app)
      if [[ -f "$candidate/Info.plist" ]]; then APP="$candidate"; break; fi ;;
  esac
done < <(find "$ROOT" "${HOME}/Library/Developer/Xcode/Archives" "${HOME}/Library/Developer/Xcode/DerivedData" -type d -name '*.app' -print0 2>/dev/null || true)
if [[ -z "$APP" ]]; then
  echo 'ERRO: Nenhum aplicativo .app compilado foi encontrado.' >&2
  echo 'Confira a etapa xcodebuild/archive ANTES de Empacotar IPA.' >&2
  echo 'O alvo Xcode se chama 3105, nao App; nao use build/Release-iphoneos/App.app.' >&2
  exit 1
fi
printf 'Aplicativo encontrado: %s\n' "$APP"
if [[ ! -d "$APP/_CodeSignature" ]]; then
  echo 'AVISO: .app sem pasta _CodeSignature; a IPA pode nao ser instalavel em um iPhone.' >&2
fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/Payload"
cp -R "$APP" "$TMP/Payload/"
(cd "$TMP" && zip -qry "$OUT/3105-HS-VIPS.ipa" Payload)
echo "IPA criada em $OUT/3105-HS-VIPS.ipa"
