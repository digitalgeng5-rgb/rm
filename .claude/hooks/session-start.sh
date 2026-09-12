#!/bin/bash
# Поднимает claude-lane-stack из вендоренной копии stack/ при старте сессии.
# Идемпотентно: безопасно запускать многократно.
set -euo pipefail

# Только для удалённой среды (Claude Code on the web). Локально не трогаем машину.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
STACK="$PROJECT_DIR/stack"

if [ ! -f "$STACK/install.sh" ]; then
  echo "session-start: stack/install.sh не найден в $STACK — пропускаю" >&2
  exit 0
fi

echo "session-start: настройка claude-lane-stack (vendored)"

# 1) Python-модули, которые требует установщик стека.
if ! python3 -c 'import jsonschema, yaml' >/dev/null 2>&1; then
  echo "session-start: ставлю python-модули jsonschema + PyYAML"
  pip install --quiet jsonschema pyyaml
fi

# 2) rsync — жёсткая зависимость install.sh.
if ! command -v rsync >/dev/null 2>&1; then
  echo "session-start: ставлю rsync"
  (apt-get update -qq || true)
  if ! apt-get install -y rsync >/dev/null 2>&1; then
    sudo apt-get install -y rsync >/dev/null 2>&1 || true
  fi
fi
if ! command -v rsync >/dev/null 2>&1; then
  echo "session-start: не удалось поставить rsync — стек не поднять" >&2
  exit 1
fi

# 3) Установка стека из локальной вендоренной копии (без обращения к сети:
#    маркетплейс плагина берётся из stack/, а не клонируется с GitHub).
export LANE_INSTALL_LOCAL_MARKETPLACE=1
bash "$STACK/install.sh"

# 4) Пробрасываем PATH к утилитам стека на всю сессию.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo 'export PATH="$HOME/.agents/bin:$PATH"' >> "$CLAUDE_ENV_FILE"
fi

echo "session-start: claude-lane-stack готов (PM: lane-pm / claude --agent dev-orchestrator)"
