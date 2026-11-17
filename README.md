# agentic-harness

Plugin de Claude Code para crear agentes de IA con LangChain/LangGraph, modelos de Anthropic (`claude-opus-5-5` por defecto) y trazas en Langfuse. Agnóstico al proveedor de nube.

Este repositorio es a la vez un **marketplace** (`.claude-plugin/marketplace.json`) y la fuente del plugin (`plugins/agentic-harness/`).

## Instalar (una vez, para todos tus proyectos)

Requisitos: Claude Code, `jq` (o `python3`), `uv` y Python 3.12+.

Dentro de Claude Code:

```
/plugin marketplace add rcronald/agentic-harness
/plugin install agentic-harness@agentic-harness
```

O desde la terminal:

```bash
claude plugin marketplace add rcronald/agentic-harness
claude plugin install agentic-harness@agentic-harness
```

Reinicia Claude Code. La primera vez, aprueba los servidores MCP del plugin (`docs-langchain`, `reference-langchain`, `langfuse-docs`).

### Actualizar

```bash
claude plugin marketplace update agentic-harness
claude plugin update agentic-harness@agentic-harness
```

Después, reinicia la sesión.

### Desinstalar

```bash
claude plugin uninstall agentic-harness@agentic-harness
claude plugin marketplace remove agentic-harness
```

### Desarrollar el plugin desde una copia local

```bash
git clone https://github.com/rcronald/agentic-harness.git
claude --plugin-dir agentic-harness/plugins/agentic-harness   # probar sin instalar
claude plugin marketplace add ./agentic-harness               # o instalar desde la copia local
```

## Usar en un proyecto

```bash
mkdir ~/code/mi-agente && cd ~/code/mi-agente && claude
```

```
/agentic-harness:new-agent soporte "responde dudas de clientes consultando la base de pedidos"
```

La primera vez, `new-agent` ejecuta `/agentic-harness:init-project`, que copia al proyecto `templates/project/`: `CLAUDE.md`, `.claude/rules/`, `.claude/settings.json`, `ruff.toml`, `pytest.ini`, `Dockerfile`, `scripts/ci.sh`, `.github/workflows/ci.yml`, `.env.example` y `.gitignore` (sin sobrescribir; en `.gitignore` y `.env.example` solo añade lo que falte). Después crea `agents/<nombre>/` desde el esqueleto probado y lo adapta al caso. Luego: `cp .env.example .env`, completa las claves y reinicia la sesión para que se carguen las reglas.

Con el agente creado:

```bash
uv run python -m agents.soporte.config              # validar .env y entorno
uv run python -m agents.soporte.cli                 # conversar por terminal
uv run python -m agents.soporte.server              # API HTTP
uv run python -m agents.soporte.evals.run_eval      # evaluación (modelo real)
scripts/ci.sh                                       # lint, formato y pruebas
docker build --build-arg AGENT=soporte -t soporte . # imagen
```

## Contenido del plugin

| Pieza | Ubicación | Qué aporta |
|---|---|---|
| Skills | `skills/` | `new-agent`, `add-tool`, `add-eval`, `instrument-langfuse`, `init-project` |
| Subagentes | `agents/` | `langchain-researcher`, `agent-architect`, `agent-reviewer` |
| MCP | `.mcp.json` | `docs-langchain`, `reference-langchain`, `langfuse-docs` (HTTP, sin credenciales) |
| Hooks | `hooks/hooks.json` → `scripts/` | `session-start`, `guard-bash`, `protect-secrets`, `post-edit` |
| Plantillas de proyecto | `templates/project/` | Lo que `init-project` instala: reglas, `CLAUDE.md`, permisos, ruff, pytest, `Dockerfile`, CI, `.env.example` |
| Esqueleto de agente | `templates/agent/` | Lo que `scaffold-agent.sh` copia a `agents/<nombre>/`: código, evaluaciones y pruebas |

Las rutas son relativas a `plugins/agentic-harness/`.

### Por qué las reglas se copian al proyecto
Un plugin no puede aportar `CLAUDE.md` ni `.claude/rules/`, y tampoco `model` ni `permissions`. Por eso viven en `templates/project/` y `init-project` las instala en cada proyecto, donde Claude Code las carga siempre.

### Alcance de los hooks
Con el plugin instalado a nivel de usuario, los hooks corren en todos tus proyectos:
- `guard-bash`, `protect-secrets` y la detección de secretos de `post-edit`: en todos. Leen la llamada con `jq` o, si falta, con `python3`; si no pueden leerla, bloquean en lugar de dejarla pasar.
- `session-start` y `ruff` de `post-edit`: solo en proyectos inicializados (los que tienen `.claude/rules/agent-design.md`), para no reformatear código ajeno.

## Qué tiene cada agente creado

| Componente | Módulo | Contenido |
|---|---|---|
| Instrucciones | `prompts.py` | System prompt versionado; fecha e idioma resueltos en cada llamada |
| Configuración | `config.py` | Objeto tipado; carga `.env` sin pisar el entorno, ignora variables vacías, valida al arrancar y exige `ANTHROPIC_API_KEY`; `python -m agents.<nombre>.config` la comprueba sin mostrar secretos. El modelo se construye solo en `build_model()` |
| Histórico de conversación | `memory.py` | Sesiones por `session_id`; backends `memory`, `sqlite` y `postgres`; recorte o resumen; reparación de llamadas a tool huérfanas |
| Límites y aprobación | `guards.py` | Llamadas al modelo y a tools por turno, presupuesto de tokens por sesión, errores de tools como texto, aprobación humana por llamada |
| Invocación | `agent.py` | `AgentRunner`: `chat`, `decide` (aprobaciones), `clear`, timeout por turno |
| Trazas | `observability.py` | Langfuse con sesión, entorno, versión, `PROMPT_VERSION` y enmascarado de datos sensibles |
| Entradas | `cli.py`, `server.py` | Terminal y API HTTP (FastAPI) con token opcional |
| Evaluación | `evals/` | Casos en `dataset.jsonl`; experimentos en Langfuse o ejecución local; juez LLM opcional |
| Pruebas | `tests/` | Tools, histórico, flujo, aprobación, límites, servidor; integración e inyección con el modelo real |

## Desarrollo

- Probar sin instalar: `claude --plugin-dir plugins/agentic-harness`
- Validar: `claude plugin validate plugins/agentic-harness && claude plugin validate .`
- Probar hooks, init y scaffold: `scripts/test-hooks.sh`
- Probar el esqueleto de punta a punta (descarga dependencias): `scripts/test-skeleton.sh`. Con `HISTORY_TEST_POSTGRES_URL` también prueba el backend de Postgres.

## Requisitos

`jq` (hooks), `uv` y Python 3.12+. `ruff` es opcional: si no está, el hook solo comprueba que el archivo compile.

## CI

**En los proyectos de agentes.** `scripts/ci.sh` es la única definición de CI: lint, formato y pruebas; `--evals` añade integración y evaluaciones con umbral (`EVAL_MIN_SCORE`). `init-project` instala `.github/workflows/ci.yml`, que:
- en cada push a `main` y en cada PR ejecuta `scripts/ci.sh`;
- bajo demanda (Actions → ci → Run workflow → `evals`) ejecuta `scripts/ci.sh --evals` en el entorno `evals`, con los secretos `ANTHROPIC_API_KEY`, `LANGFUSE_PUBLIC_KEY` y `LANGFUSE_SECRET_KEY`, y las variables opcionales `LANGFUSE_BASE_URL` y `EVAL_MIN_SCORE`.

Para otro proveedor de CI basta con ejecutar el mismo script.

**En este repositorio.** `.github/workflows/plugin-ci.yml` valida manifiestos y frontmatter, ejecuta `scripts/test-hooks.sh` y `scripts/test-skeleton.sh` con un Postgres de servicio.

## Añadir un proveedor de nube más adelante

Añade una regla en `templates/project/.claude/rules/` y una skill de despliegue en `skills/`. `templates/project/.claude/rules/deployment.md` indica qué mantiene hoy el código portable.

## Documentación

| Documento | Para quién |
|---|---|
| [Guía de uso](docs/guia-de-uso.md) | Quien quiere crear y operar agentes con el plugin: instalación, primer agente, configuración, ejecución, evaluación, despliegue y problemas frecuentes |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Quien quiere mejorar el plugin: entorno, issues, ramas, commits, PR y releases |
| [CHANGELOG.md](CHANGELOG.md) | Qué cambia en cada versión y cómo aplicarlo a agentes existentes |

## Versiones

Versionado semántico; los cambios de cada versión y cómo aplicarlos a agentes existentes están en [CHANGELOG.md](CHANGELOG.md). El criterio está en [CLAUDE.md](CLAUDE.md#versiones-y-publicación).

## Licencia

[MIT](LICENSE).
