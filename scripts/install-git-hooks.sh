#!/usr/bin/env bash
# Instala un hook commit-msg que valida el formato de los commits (opcional, recomendado).
#   scripts/install-git-hooks.sh
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
hook="$(git -C "$root" rev-parse --git-path hooks)/commit-msg"
cat >"$hook" <<'HOOK'
#!/usr/bin/env bash
exec "$(git rev-parse --show-toplevel)/scripts/check-conventions.sh" commit-msg "$1"
HOOK
chmod +x "$hook"
echo "Hook commit-msg instalado en $hook"
