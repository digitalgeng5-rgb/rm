# rm — claude-lane-stack, закреплённый в репозитории

Этот репозиторий фиксирует агент-оркестратор **claude-lane-stack** так, чтобы он
**поднимался автоматически в каждой сессии** Claude Code on the web.

- Апстрим: <https://github.com/VKirill/claude-lane-stack>
- Закреплённая версия: **v1.27.0** (см. [`VERSION`](VERSION))
- Оркестратор: `dev-orchestrator` (PM). Запуск: `lane-pm` или `claude --agent dev-orchestrator`

## Как это работает

1. Весь стек вендорен в [`stack/`](stack/) — репозиторий самодостаточен и не
   зависит от доступности апстрима в момент старта сессии.
2. При старте сессии срабатывает SessionStart-хук
   [`.claude/hooks/session-start.sh`](.claude/hooks/session-start.sh)
   (зарегистрирован в [`.claude/settings.json`](.claude/settings.json)). Он:
   - ставит зависимости установщика — `rsync`, python-модули `jsonschema` и `PyYAML`;
   - запускает `stack/install.sh` из локальной копии
     (`LANE_INSTALL_LOCAL_MARKETPLACE=1` — плагин ставится из `stack/`, без обращения к сети);
   - пробрасывает `~/.agents/bin` в `PATH` на всю сессию.
3. Хук идемпотентен и работает только в удалённой среде
   (`CLAUDE_CODE_REMOTE=true`) — локальную машину он не трогает.

> **Важно:** чтобы хук применялся ко всем будущим сессиям, он должен быть в
> **ветке по умолчанию** репозитория. Смёрдженный в `main` — работает везде.

## Что появляется в сессии

- **Плагин Claude Code** `lane-stack@claude-lane-stack` (агенты, команды, скиллы).
- **Агенты (17):** `dev-orchestrator`, `run-supervisor`, `night-reviewer`,
  `emergency-writer`, `project-onboarder`, `docs-maintainer`, `memory-maintainer`,
  `design-lead`, `copy-lead`, `seo-specialist`, `lane-supervisor`, `tavily`,
  `codex-implementer`, `codex-reviewer`, `codex-onboarder`, `codex-docs-maintainer`,
  `grok-implementer`.
- **Слэш-команды:** `/app-architect`, `/info`, `/project-onboard`, `/resume-project`.
- **Скиллы** для writer-агентов (дизайн/UX, копирайт, SEO/DrMax, русский текст,
  память проекта) в `~/.agents/skills` + PM-скиллы в `~/.agents/pm-skills`.
- **CLI-утилиты** стека в `~/.agents/bin` (`lane-pm`, `lane-ctl`, `run-controller`,
  `night-shift-all`, `agents-doctor` и др.).

## Ограничение

Полный конвейер «днём катим — ночью ревью» рассчитан на внешние writer-CLI
(Codex, Qwen, Kimi, Grok, Gemini/AGY). Без них работает ядро на Claude
(`dev-orchestrator` + Claude-субагенты); ночные Codex-ревью и аварийные
writer'ы требуют подключения и авторизации соответствующих CLI.

## Обновление версии стека

1. `git clone --depth 1 --branch <новый тег> https://github.com/VKirill/claude-lane-stack`
2. Скопировать содержимое в `stack/` (без `.git`).
3. Обновить [`VERSION`](VERSION), закоммитить, смёрджить в `main`.
