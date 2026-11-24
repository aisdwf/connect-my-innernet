#!/usr/bin/env bash
set -euo pipefail

# Restore MFC1442/ from the encrypted parts in this directory.
# Uses the same .secret_key as scripts/inner_pull.sh. Does not need the internet.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$DIR/../.." && pwd)"
DEST="${1:-$DIR/MFC1442}"

KEY_FILE="${INNERNET_KEY_FILE:-}"
if [[ -z "$KEY_FILE" ]]; then
  if [[ -f "$ROOT_DIR/.secret_key" ]]; then
    KEY_FILE="$ROOT_DIR/.secret_key"
  elif [[ -f "$HOME/.innernet_key" ]]; then
    KEY_FILE="$HOME/.innernet_key"
  fi
fi
if [[ -z "$KEY_FILE" || ! -f "$KEY_FILE" ]]; then
  echo "[错误] 未找到密钥文件。请在仓库根目录放 .secret_key，内容与外网一致。" >&2
  exit 1
fi

SECRET_PASS="$(grep -v '^[[:space:]]*#' "$KEY_FILE" | grep -v '^[[:space:]]*$' | head -n 1 | tr -d '\r\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
if [[ -z "$SECRET_PASS" ]]; then
  echo "[错误] 密钥文件为空: $KEY_FILE" >&2
  exit 1
fi

shopt -s nullglob
parts=("$DIR"/parts/mfc.enc.*)
if [[ ${#parts[@]} -eq 0 ]]; then
  echo "[错误] 没有找到分片: $DIR/parts/mfc.enc.*" >&2
  exit 1
fi
IFS=$'\n' parts=($(printf '%s\n' "${parts[@]}" | sort))
unset IFS

if command -v shasum >/dev/null 2>&1; then
  (cd "$DIR/parts" && shasum -a 256 -c "$DIR/PARTS.sha256")
elif command -v sha256sum >/dev/null 2>&1; then
  (cd "$DIR/parts" && sha256sum -c "$DIR/PARTS.sha256")
else
  echo "[提示] 没有 shasum/sha256sum，跳过分片校验。" >&2
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "[解密] ${#parts[@]} 个分片 -> $DEST"
cat "${parts[@]}" | openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass "pass:${SECRET_PASS}" | tar -xf - -C "$WORKDIR"

rm -rf "$DEST"
mv "$WORKDIR/MFC1442" "$DEST"
echo "[成功] 已还原到 $DEST"
echo "下一步（校验再装）:"
echo "  powershell -ExecutionPolicy Bypass -File \"$DEST/verify_mfc.ps1\" -Dir \"$DEST\""
echo "  powershell -ExecutionPolicy Bypass -File \"$DEST/install_atlmfc.ps1\" -Dir \"$DEST\""
