#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# [内网接收脚本] inner_pull.sh
# 功能：
# 1. 自动执行 git pull（若指定 --no-pull 则仅解密本地已有的 payload.enc）
# 2. 自动从 .secret_key（或 ~/.innernet_key）读取密码，无需手动输入
# 3. 解密 payload.enc 并解压缩还原到 tasks/ 目录
# ==============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENCRYPTED_FILE="$ROOT_DIR/payload.enc"

# 1. 查找密钥文件
KEY_FILE="${INNERNET_KEY_FILE:-}"
if [[ -z "$KEY_FILE" ]]; then
  if [[ -f "$ROOT_DIR/.secret_key" ]]; then
    KEY_FILE="$ROOT_DIR/.secret_key"
  elif [[ -f "$HOME/.innernet_key" ]]; then
    KEY_FILE="$HOME/.innernet_key"
  fi
fi

if [[ -z "$KEY_FILE" || ! -f "$KEY_FILE" ]]; then
  echo "[错误] 未找到密钥文件！请在内网项目根目录放置 .secret_key 文件（写入与外网一致的一行密码）。" >&2
  echo "       例如: echo 'my_secret_password' > .secret_key" >&2
  exit 1
fi

SECRET_PASS="$(grep -v '^[[:space:]]*#' "$KEY_FILE" | grep -v '^[[:space:]]*$' | head -n 1 | tr -d '\r\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

if [[ -z "$SECRET_PASS" ]]; then
  echo "[错误] 密钥文件 ($KEY_FILE) 内容为空！" >&2
  exit 1
fi

# 2. 拉取最新代码（除非传入 --no-pull）
if [[ "${1:-}" != "--no-pull" ]]; then
  if git remote | grep -q .; then
    echo "[Git] 正在从远端拉取最新加密包..."
    git pull --ff-only || git pull --rebase
  else
    echo "[提示] 未检测到 git remote，跳过 git pull，直接尝试解密本地 payload.enc..."
  fi
fi

if [[ ! -f "$ENCRYPTED_FILE" ]]; then
  echo "[错误] 未找到加密包文件: $ENCRYPTED_FILE" >&2
  exit 1
fi

# 3. 解密并解压到 tasks/
echo "[解密] 正在使用密钥文件 ($KEY_FILE) 解密 payload.enc ..."
rm -rf "$ROOT_DIR/tasks"
mkdir -p "$ROOT_DIR/tasks"

if openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass "pass:${SECRET_PASS}" -in "$ENCRYPTED_FILE" | tar -xzf - -C "$ROOT_DIR"; then
  echo "[成功] 解密完成！当前 tasks/ 目录下的问题列表："
  find "$ROOT_DIR/tasks" -mindepth 1 -maxdepth 1 -type d | sort | sed 's|^.*/|  - |'
else
  echo "[失败] 解密失败，请检查内网 .secret_key 中的密码是否与外网完全一致！" >&2
  exit 1
fi
