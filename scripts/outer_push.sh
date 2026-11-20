#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# [外网发送脚本] outer_push.sh
# 功能：
# 1. 自动清理 tasks/ 下超出上限（默认保留最近 10 个）的历史问题文件夹
# 2. 自动读取本地密钥文件 (.secret_key 或 ~/.innernet_key)
# 3. 将 tasks/ 打包压缩并用 AES-256-CBC (PBKDF2) 加密为 payload.enc
# 4. 自动提交并推送到 Git 远端（默认仅加密上传 payload.enc）
# ==============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MAX_TASKS="${MAX_TASKS:-10}"
TASKS_DIR="$ROOT_DIR/tasks"
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
  echo "[错误] 未找到密钥文件！请在项目根目录创建 .secret_key 文件（写入一行密码）。" >&2
  echo "       例如: echo 'my_secret_password' > .secret_key" >&2
  exit 1
fi

# 读取第一行非空非注释内容作为密码，并去除回车换行与首尾空格
SECRET_PASS="$(grep -v '^[[:space:]]*#' "$KEY_FILE" | grep -v '^[[:space:]]*$' | head -n 1 | tr -d '\r\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

if [[ -z "$SECRET_PASS" ]]; then
  echo "[错误] 密钥文件 ($KEY_FILE) 内容为空！" >&2
  exit 1
fi

mkdir -p "$TASKS_DIR"

# 2. 清理超出数量限制的旧任务文件夹（按名称排序，保留最后 MAX_TASKS 个）
TASK_DIRS=()
while IFS= read -r dir; do
  [[ -n "$dir" ]] && TASK_DIRS+=("$dir")
done < <(find "$TASKS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

TOTAL_TASKS=${#TASK_DIRS[@]}
if (( TOTAL_TASKS > MAX_TASKS )); then
  REMOVE_COUNT=$(( TOTAL_TASKS - MAX_TASKS ))
  echo "[清理] 当前共有 $TOTAL_TASKS 个任务文件夹，超出上限 ($MAX_TASKS)，正在清理最早的 $REMOVE_COUNT 个..."
  for (( i=0; i<REMOVE_COUNT; i++ )); do
    echo "  - 删除旧任务: $(basename "${TASK_DIRS[$i]}")"
    rm -rf "${TASK_DIRS[$i]}"
  done
fi

# 3. 打包并加密 tasks/ 目录
echo "[加密] 正在打包并加密 tasks/ 目录 -> payload.enc ..."
tar -czf - -C "$ROOT_DIR" tasks | openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 -pass "pass:${SECRET_PASS}" -out "$ENCRYPTED_FILE"

PAYLOAD_SIZE="$(du -h "$ENCRYPTED_FILE" | cut -f1)"
echo "[完成] 已生成加密包 payload.enc (大小: ${PAYLOAD_SIZE})"

# 4. 如果传入 --no-git 或未配置 git remote，则只生成加密包不自动 push
if [[ "${1:-}" == "--no-git" ]]; then
  echo "[提示] 已指定 --no-git，跳过 Git 提交与推送。"
  exit 0
fi

git add "$ENCRYPTED_FILE" agent.md .gitignore .secret_key.example scripts/ tasks/.gitkeep archives/.gitkeep 2>/dev/null || git add "$ENCRYPTED_FILE"

if git diff --cached --quiet; then
  echo "[Git] 没有检测到新的变更需要提交。"
else
  TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
  git commit -m "sync: update encrypted payload ($TIMESTAMP)"
fi

if git remote | grep -q .; then
  echo "[Git] 正在推送到远端仓库..."
  git push
  echo "[成功] 加密数据包已推送到 GitHub！内网现在可以执行 ./scripts/inner_pull.sh 拉取解密。"
else
  echo "[提示] 本地已完成 Git Commit，但尚未配置 Git 远端仓库 (git remote add origin <URL>)。"
fi
