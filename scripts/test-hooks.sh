#!/usr/bin/env bash
# Prueba los hooks y el init del plugin con entradas simuladas. Uso: scripts/test-hooks.sh
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
h="$root/plugins/agentic-harness/scripts"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# Proyecto simulado, inicializado con el plugin
proj="$tmp/proyecto"
bash "$h/init-project.sh" "$proj" >/dev/null
export CLAUDE_PROJECT_DIR="$proj"
fails=0

# check <descripción> <esperado: deny|pass|block> <hook> <json de entrada>
check() {
  local desc=$1 want=$2 hook=$3 input=$4 out code got
  out=$(printf '%s' "$input" | bash "$h/$hook" 2>&1)
  code=$?
  if [ "$code" -eq 2 ]; then got=block
  elif grep -q '"permissionDecision": *"deny"' <<<"$out"; then got=deny
  else got=pass
  fi
  if [ "$got" = "$want" ]; then
    printf 'ok    %s\n' "$desc"
  else
    printf 'FALLO %s (esperado %s, obtenido %s)\n      %s\n' "$desc" "$want" "$got" "$out"
    fails=$((fails + 1))
  fi
}

cmd() { jq -n --arg c "$1" '{tool_input:{command:$c}}'; }
file() { jq -n --arg p "$1" '{tool_input:{file_path:$p}}'; }
envf=".env"

check "bash: volcar .env"             deny guard-bash.sh "$(cmd "cat $envf")"
check "bash: buscar en .env.local"    deny guard-bash.sh "$(cmd "cd x && grep KEY $envf.local")"
check "bash: leer .env.example"       pass guard-bash.sh "$(cmd "cat $envf.example")"
check "bash: ejecutar pruebas"        pass guard-bash.sh "$(cmd "uv run pytest -q")"

check "archivo: .env"                 deny protect-secrets.sh "$(file "$proj/$envf")"
check "archivo: .env.prod"            deny protect-secrets.sh "$(file "$proj/$envf.prod")"
check "archivo: clave .pem"           deny protect-secrets.sh "$(file "$proj/certs/server.pem")"
check "archivo: secrets/"             deny protect-secrets.sh "$(file "$proj/secrets/token.txt")"
check "archivo: .env.example"         pass protect-secrets.sh "$(file "$proj/$envf.example")"
check "archivo: agent.py"             pass protect-secrets.sh "$(file "$proj/agents/x/agent.py")"

printf 'KEY = "sk-ant-%s"\n' "abcdefghijklmnopqrstuvwxyz0123" >"$tmp/leak.py"
printf 'def f(:\n    pass\n' >"$tmp/bad.py"
printf 'def f() -> int:\n    return 1\n' >"$tmp/good.py"
check "post-edit: secreto incrustado" block post-edit.sh "$(file "$tmp/leak.py")"
check "post-edit: error de sintaxis"  block post-edit.sh "$(file "$tmp/bad.py")"
check "post-edit: archivo correcto"   pass  post-edit.sh "$(file "$tmp/good.py")"

# Con ambos ejecutables presentes, el hook usa la versión del proyecto.
mkdir -p "$proj/.venv/bin" "$tmp/bin-ruff"
export RUFF_TEST_LOG="$tmp/ruff.log"
cat >"$proj/.venv/bin/ruff" <<'EOF'
#!/bin/bash
printf 'proyecto:%s\n' "$1" >>"$RUFF_TEST_LOG"
EOF
cat >"$tmp/bin-ruff/ruff" <<'EOF'
#!/bin/bash
printf 'global:%s\n' "$1" >>"$RUFF_TEST_LOG"
EOF
chmod +x "$proj/.venv/bin/ruff" "$tmp/bin-ruff/ruff"
PATH="$tmp/bin-ruff:$PATH" check "post-edit: ruff del proyecto" pass post-edit.sh "$(file "$tmp/good.py")"
if [ "$(cat "$RUFF_TEST_LOG")" = $'proyecto:format\nproyecto:check' ]; then
  echo "ok    post-edit: prefiere ruff de .venv a ruff global"
else
  echo "FALLO post-edit: no priorizó ruff de .venv"
  fails=$((fails + 1))
fi
mv "$proj/.venv/bin/ruff" "$proj/.venv/bin/ruff-disabled"
: >"$RUFF_TEST_LOG"
PATH="$tmp/bin-ruff:$PATH" check "post-edit: ruff global" pass post-edit.sh "$(file "$tmp/good.py")"
if [ "$(cat "$RUFF_TEST_LOG")" = $'global:format\nglobal:check' ]; then
  echo "ok    post-edit: usa ruff global si no hay ruff de .venv"
else
  echo "FALLO post-edit: no recurrió a ruff global"
  fails=$((fails + 1))
fi

# Sin jq: respaldo con python3. Sin jq ni python3: bloquea (falla cerrado).
mkbin() {  # mkbin <dir> <comandos…>: PATH mínimo con solo esos comandos
  local dir=$1; shift; mkdir -p "$dir"
  for c in "$@"; do ln -sf "$(command -v "$c")" "$dir/$c"; done
}
mkbin "$tmp/bin-py" bash cat grep basename dirname tr head python3
mkbin "$tmp/bin-none" bash cat grep basename dirname tr head
PATH="$tmp/bin-py" check   "sin jq (python3): bloquea .env"   deny protect-secrets.sh "$(file "$proj/$envf")"
PATH="$tmp/bin-py" check   "sin jq (python3): permite agent.py" pass protect-secrets.sh "$(file "$proj/agents/x/agent.py")"
PATH="$tmp/bin-py" check   "sin jq (python3): bash cat .env"  deny guard-bash.sh "$(cmd "cat $envf")"
PATH="$tmp/bin-none" check "sin parser: bloquea lectura"      deny protect-secrets.sh "$(file "$proj/agents/x/agent.py")"
PATH="$tmp/bin-none" check "sin parser: bloquea bash"         deny guard-bash.sh "$(cmd "ls")"
PATH="$tmp/bin-none" check "sin parser: post-edit avisa"      block post-edit.sh "$(file "$tmp/good.py")"
check "entrada no JSON: bloquea"      deny protect-secrets.sh "esto no es json"
check "nombre con comillas: JSON válido" deny protect-secrets.sh "$(file "$proj/a\"b/.env")"
out=$(file "$proj/a\"b/.env" | bash "$h/protect-secrets.sh")
if printf '%s' "$out" | jq -e . >/dev/null 2>&1; then echo "ok    deny produce JSON válido"
else echo "FALLO deny produce JSON inválido: $out"; fails=$((fails + 1)); fi

# Fuera de un proyecto inicializado: no hay ruff ni contexto, pero sí detección de secretos
mkdir -p "$tmp/otro"
printf 'x=1\n' >"$tmp/otro/fmt.py"
CLAUDE_PROJECT_DIR="$tmp/otro" check "post-edit: otro proyecto pasa" pass post-edit.sh "$(file "$tmp/otro/fmt.py")"
CLAUDE_PROJECT_DIR="$tmp/otro" check "post-edit: secreto en otro proyecto" block post-edit.sh "$(file "$tmp/leak.py")"
if [ -z "$(CLAUDE_PROJECT_DIR="$tmp/otro" bash "$h/session-start.sh")" ]; then
  echo "ok    session-start: silencioso fuera del harness"
else echo "FALLO session-start: imprime fuera del harness"; fails=$((fails + 1)); fi

# init-project: idempotente y sin duplicar líneas
out=$(bash "$h/init-project.sh" "$proj")
if grep -q "omitido (ya existe): CLAUDE.md" <<<"$out" && grep -q ".env.example (0 línea" <<<"$out" \
   && [ "$(grep -c '^ANTHROPIC_API_KEY=' "$proj/.env.example")" -eq 1 ]; then
  echo "ok    init-project: segunda ejecución no sobrescribe ni duplica"
else echo "FALLO init-project: $out"; fails=$((fails + 1)); fi
printf 'node_modules/\n' >"$tmp/otro/.gitignore"
bash "$h/init-project.sh" "$tmp/otro" >/dev/null
if grep -q '^node_modules/' "$tmp/otro/.gitignore" && grep -q '^\.env$' "$tmp/otro/.gitignore"; then
  echo "ok    init-project: combina .gitignore existente"
else echo "FALLO init-project: .gitignore"; fails=$((fails + 1)); fi

# scaffold-agent: nombre válido, sin sobrescribir y sin marcadores
s="$h/scaffold-agent.sh"
if ! bash "$s" "Mal-Nombre" "$proj" >/dev/null 2>&1 && bash "$s" ventas "$proj" >/dev/null \
   && ! bash "$s" ventas "$proj" >/dev/null 2>&1 && ! grep -rq '__agent_name__' "$proj/agents/ventas" \
   && grep -q 'AGENT_NAME = "ventas"' "$proj/agents/ventas/config.py"; then
  echo "ok    scaffold-agent: valida nombre, no sobrescribe y sustituye marcadores"
else echo "FALLO scaffold-agent"; fails=$((fails + 1)); fi

echo "--- salida de session-start.sh"
bash "$h/session-start.sh"

[ "$fails" -eq 0 ] && echo "Todos los hooks pasan." || echo "$fails prueba(s) fallaron."
exit "$fails"
