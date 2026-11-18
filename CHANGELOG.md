# Changelog

Todos los cambios relevantes del plugin `agentic-harness`. El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y las versiones, [versionado semántico](https://semver.org/lang/es/) con el criterio de `CLAUDE.md`.

Cada versión indica si los proyectos o agentes ya creados tienen que hacer algo: el plugin no modifica el código que el esqueleto ya copió.

## [Sin publicar]

### Corregido

- **PARCHE:** `post-edit` prefiere el Ruff de `.venv` al del `PATH` para respetar la versión del proyecto.

## [1.0.0] - 2026-11-17

Primera versión pública.

### Añadido
- **Plugin y marketplace** instalables con `/plugin marketplace add rcronald/agentic-harness`.
- **Skills:**
  - `new-agent`: crea un agente desde el esqueleto y lo adapta al caso.
  - `add-tool`: añade una tool con tipos, docstring, errores, aprobación humana y pruebas.
  - `add-eval`: crea y ejecuta el conjunto de evaluación.
  - `instrument-langfuse`: añade o revisa las trazas.
  - `init-project`: prepara un proyecto para crear agentes.
- **Subagentes:** `langchain-researcher`, `agent-architect` y `agent-reviewer`.
- **Servidores MCP de documentación:** `docs-langchain`, `reference-langchain` y `langfuse-docs`.
- **Hooks:**
  - Bloquean la lectura de `.env` y credenciales, detectan secretos incrustados y pasan `ruff` a los archivos Python.
  - Leen la llamada con `jq` o, si falta, con `python3`; si no pueden leerla, bloquean.
  - El formateo y el resumen del entorno solo actúan en proyectos inicializados.
- **Esqueleto de agente** (`templates/agent/`):
  - Configuración tipada: carga `.env` sin pisar el entorno, trata las variables vacías como no definidas, valida al arrancar y exige `ANTHROPIC_API_KEY`. `python -m agents.<nombre>.config` la comprueba sin mostrar secretos.
  - Histórico por `session_id` con backends `memory`, `sqlite` y `postgres`, recorte o resumen, y reparación de llamadas a tool sin resultado.
  - Límites de llamadas al modelo y a tools por turno, timeout por turno y presupuesto de tokens por sesión.
  - Aprobación humana por llamada para tools con efectos, con modo prueba (`AGENT_DRY_RUN`).
  - Trazas en Langfuse con sesión, entorno, versión, `PROMPT_VERSION` y enmascarado de datos sensibles.
  - CLI, servidor HTTP con token opcional y evaluaciones (local o como experimento de Langfuse, con juez LLM opcional).
  - Pruebas de tools, histórico, flujo, aprobación, límites, servidor y configuración. Las de integración, inyección y Postgres se ejecutan bajo demanda.
- **Plantillas de proyecto** (`templates/project/`):
  - Reglas en `.claude/rules/`, `CLAUDE.md` y permisos.
  - Configuración de `ruff` y `pytest`.
  - `Dockerfile` independiente del proveedor de nube.
  - `scripts/ci.sh` y `.github/workflows/ci.yml`, con evaluaciones bajo demanda.
- **CI del repositorio:**
  - Valida los manifiestos, la versión y el CHANGELOG.
  - Prueba los hooks y el esqueleto de punta a punta con Postgres.
- Licencia MIT.

[Sin publicar]: https://github.com/rcronald/agentic-harness/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/rcronald/agentic-harness/releases/tag/v1.0.0
