# agentic-harness (fuente del plugin)

Este repositorio contiene el plugin de Claude Code `agentic-harness` (`plugins/agentic-harness/`) y su marketplace (`.claude-plugin/marketplace.json`). Aquí se desarrolla el plugin; los agentes se crean en otros proyectos con él instalado.

- Las reglas que se aplican a los proyectos de agentes están en `plugins/agentic-harness/templates/project/.claude/rules/`; si cambias una, cambia también las skills o subagentes que la citan.
- El esqueleto de agente está en `plugins/agentic-harness/templates/agent/` (marcador `__agent_name__`). Sigue la regla de documentación primero al cambiarlo: consulta los MCP de LangChain y Langfuse.
- En skills y subagentes, las rutas internas del plugin usan `${CLAUDE_PLUGIN_ROOT}` y los nombres van con prefijo: `agentic-harness:<subagente>`, `/agentic-harness:<skill>`, `mcp__plugin_agentic-harness_<servidor>__<tool>`.
- Sigue `CONTRIBUTING.md`: rama `<tipo>/<issue>-<descripcion>`, commits Conventional Commits en español (`feat(skills): añade …`), PR con squash merge y nunca commits directos a `main`. `scripts/check-conventions.sh` valida títulos, ramas y mensajes.
- Cada cambio relevante se anota en `CHANGELOG.md`, en la sección `[Sin publicar]`. La versión no se sube en cada commit: ver "Versiones y publicación".
- La CI del repositorio (`.github/workflows/plugin-ci.yml`) ejecuta las mismas pruebas que se listan abajo, salvo `claude plugin validate`.
- Antes de dar un cambio por terminado: `scripts/test-hooks.sh`, `scripts/test-skeleton.sh` (si tocaste el esqueleto o las plantillas), `claude plugin validate plugins/agentic-harness` y `claude plugin validate .`.

## Versiones y publicación

Versionado semántico. La "API" del plugin es lo que usan las personas y los proyectos ya creados: nombres de skills y subagentes, argumentos de los scripts (`init-project.sh`, `scaffold-agent.sh`), estructura de `templates/`, variables de entorno del esqueleto y lo que bloquean los hooks.

| Cambio | Subida | Ejemplos |
|---|---|---|
| Rompe algo que ya se usa | MAYOR | Renombrar o quitar una skill o subagente; cambiar la estructura de `agents/<nombre>/` o los argumentos de un script; quitar o renombrar una variable de entorno; que un hook bloquee algo que antes permitía |
| Añade algo compatible | MENOR | Skill, subagente o regla nueva; función nueva del esqueleto; backend o variable opcional nuevos |
| Corrige sin cambiar el uso | PARCHE | Errores, documentación, ajustes de la CI o de los workflows |

- **Se versiona al publicar, no en cada commit.** Los cambios se acumulan en `[Sin publicar]`. Claude Code solo ofrece la actualización cuando cambia `version`, así que una versión puede agrupar varios commits.
- **El esqueleto se copia, no se actualiza.** Los agentes ya creados no cambian al actualizar el plugin. Un cambio en `templates/` solo es MAYOR si cambia cómo se usan las skills o los scripts; si no, es MENOR, y el CHANGELOG explica cómo aplicarlo a agentes existentes ("Migración").
- **Para publicar una versión:**
  1. Elige la subida según la tabla, a partir de lo que hay en `[Sin publicar]`.
  2. Renombra `[Sin publicar]` a `[X.Y.Z] - AAAA-MM-DD`, abre una sección `[Sin publicar]` vacía y actualiza los enlaces del final.
  3. Pon `X.Y.Z` en `plugin.json` y en las dos entradas de `marketplace.json`.
  4. Haz los pasos 2 y 3 en la rama `chore/release-vX.Y.Z` y abre un PR titulado `chore(release): vX.Y.Z`.
  5. Tras fusionarlo, etiqueta el commit resultante en `main` con `git tag -a vX.Y.Z -m "agentic-harness vX.Y.Z"` y `git push origin vX.Y.Z`. El workflow `release.yml` comprueba la versión y crea la release de GitHub con las notas del CHANGELOG.
- El tipo de los commits acumulados orienta la subida: algún `!` o `BREAKING CHANGE` → MAYOR; algún `feat` → MENOR; solo `fix`/`perf` → PARCHE; solo `docs`/`ci`/`test`/`chore` → no hace falta publicar.
- La CI exige que las tres versiones coincidan y que la versión tenga su entrada en el CHANGELOG.
