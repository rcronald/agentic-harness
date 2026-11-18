#!/usr/bin/env bash
# PostToolUse(Edit|Write): detecta secretos incrustados (en cualquier proyecto) y pasa ruff
# sobre archivos Python (solo en proyectos inicializados con el harness).
# exit 2 -> stderr vuelve al modelo para que lo corrija.
set -u
. "$(dirname "$0")/lib.sh"
hook_input
if ! path=$(json_field tool_input.file_path); then
  echo "$PARSER_MISSING No se revisó el archivo en busca de secretos." >&2
  exit 2
fi
[ -f "$path" ] || exit 0

# 1) Secretos incrustados (en cualquier archivo de texto)
if grep -IEnq 'sk-ant-[A-Za-z0-9_-]{20,}|sk-lf-[A-Za-z0-9-]{20,}|AIza[0-9A-Za-z_-]{35}|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----' "$path"; then
  echo "Posible secreto incrustado en $path. Elimínalo y léelo de una variable de entorno." >&2
  exit 2
fi

# 2) Formato y lint de Python, solo en proyectos del harness
is_harness_project || exit 0
case "$path" in
  *.py)
    if [ -x "${CLAUDE_PROJECT_DIR:-.}/.venv/bin/ruff" ]; then RUFF=("${CLAUDE_PROJECT_DIR:-.}/.venv/bin/ruff")
    elif command -v ruff >/dev/null 2>&1; then RUFF=(ruff)
    else
      if ! out=$(python3 -m py_compile "$path" 2>&1); then
        printf '%s\n' "$out" | head -20 >&2
        exit 2
      fi
      exit 0
    fi
    "${RUFF[@]}" format -q "$path" >/dev/null 2>&1
    if ! out=$("${RUFF[@]}" check --fix -q "$path" 2>&1); then
      printf 'ruff encontró problemas en %s:\n%s\n' "$path" "$out" | head -40 >&2
      exit 2
    fi
    ;;
esac
exit 0
