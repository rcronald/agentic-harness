# Cómo contribuir

Gracias por querer mejorar `agentic-harness`. Este documento explica cómo preparar el entorno, qué convenciones seguimos (issues, ramas, commits y PR) y cómo se publica una versión. Para **usar** el plugin, consulta la [guía de uso](docs/guia-de-uso.md).

## Índice
1. [Antes de empezar](#1-antes-de-empezar)
2. [Entorno de desarrollo](#2-entorno-de-desarrollo)
3. [Estructura del repositorio](#3-estructura-del-repositorio)
4. [Flujo de trabajo](#4-flujo-de-trabajo)
5. [Issues](#5-issues)
6. [Ramas](#6-ramas)
7. [Commits](#7-commits)
8. [Pull requests](#8-pull-requests)
9. [Qué probar según lo que cambies](#9-qué-probar-según-lo-que-cambies)
10. [Guía de estilo](#10-guía-de-estilo)
11. [Versiones y releases](#11-versiones-y-releases)
12. [Seguridad](#12-seguridad)

---

## 1. Antes de empezar

- **Cambios pequeños** (erratas, documentación, un error evidente): abre directamente un PR.
- **Cualquier otro cambio**: abre antes un [issue](#5-issues) para acordar el enfoque. Así no inviertes tiempo en algo que luego no encaja.
- Las contribuciones se publican bajo la [licencia MIT](LICENSE).

## 2. Entorno de desarrollo

Requisitos: Claude Code, `git`, `gh` (opcional), `jq`, `uv` y Python 3.12+. Docker o Podman solo si quieres probar la imagen o Postgres en local.

```bash
git clone https://github.com/rcronald/agentic-harness.git
cd agentic-harness

# Probar el plugin desde tu copia, sin instalarlo
claude --plugin-dir plugins/agentic-harness

# O instalarlo desde tu copia (los cambios se leen directamente de la carpeta)
claude plugin marketplace add ./
claude plugin install agentic-harness@agentic-harness
```

Si ya lo tenías instalado desde GitHub, desinstálalo antes (`claude plugin uninstall agentic-harness@agentic-harness` y `claude plugin marketplace remove agentic-harness`) para no tener dos fuentes con el mismo nombre.

## 3. Estructura del repositorio

```
.
├── .claude-plugin/marketplace.json     # catálogo: este repo es un marketplace
├── plugins/agentic-harness/            # el plugin
│   ├── .claude-plugin/plugin.json      # nombre, versión y metadatos
│   ├── skills/<nombre>/SKILL.md        # /agentic-harness:<nombre>
│   ├── agents/<nombre>.md              # subagentes agentic-harness:<nombre>
│   ├── hooks/hooks.json                # registro de hooks → scripts/
│   ├── scripts/                        # hooks, init-project.sh, scaffold-agent.sh
│   ├── .mcp.json                       # servidores MCP de documentación
│   └── templates/
│       ├── project/                    # lo que init-project copia a cada proyecto
│       └── agent/                      # esqueleto que scaffold-agent copia a agents/<nombre>/
├── scripts/                            # pruebas y utilidades del repositorio
├── docs/                               # documentación para usuarios
└── .github/                            # CI, releases y plantillas de issues y PR
```

Dos ideas clave:
- **`templates/` se copia, no se ejecuta en sitio.** El esqueleto usa el marcador `__agent_name__`, que `scaffold-agent.sh` sustituye. Para probarlo hay que generar un proyecto (`scripts/test-skeleton.sh` lo hace por ti).
- **Documentación primero.** Antes de cambiar código que use LangChain, LangGraph o Langfuse, consulta los MCP de documentación (o el subagente `agentic-harness:langchain-researcher`): sus APIs cambian a menudo.

## 4. Flujo de trabajo

1. Abre o elige un issue y asígnatelo (o comenta que lo vas a hacer).
2. Crea una rama desde `main` actualizado, con el [nombre convenido](#6-ramas).
3. Haz commits pequeños con el [formato convenido](#7-commits).
4. Ejecuta las [pruebas que correspondan](#9-qué-probar-según-lo-que-cambies).
5. Añade tu cambio a la sección `[Sin publicar]` de `CHANGELOG.md`, salvo que sea solo de CI o de estilo.
6. Abre un PR hacia `main` rellenando la plantilla y enlazando el issue.
7. Tras la revisión y con la CI en verde, se fusiona con **squash merge**: el título del PR se convierte en el commit de `main`.

Nunca se hacen commits directos a `main`; también las versiones se publican mediante PR.

Opcional, pero recomendado: `scripts/install-git-hooks.sh` instala un hook `commit-msg` que valida el formato de cada commit antes de crearlo.

## 5. Issues

Usa las plantillas de [nuevo issue](https://github.com/rcronald/agentic-harness/issues/new/choose):

| Plantilla | Cuándo |
|---|---|
| **Error** | Algo no funciona como dice la documentación |
| **Propuesta** | Una función, skill o cambio nuevo |
| **Pregunta** | Para dudas, usa mejor [Discussions](https://github.com/rcronald/agentic-harness/discussions) si están activas; si no, un issue con la etiqueta `question` |

Un buen issue:
- Tiene un título que describe el problema, no la solución: "El hook bloquea `.env.example` en Windows", no "Cambiar regex".
- Incluye la versión del plugin (`claude plugin list`) y de Claude Code (`claude --version`).
- En errores: pasos para reproducirlo, qué esperabas y qué obtuviste. Los logs van **sin secretos**.
- Aborda un solo tema; si hay dos, abre dos issues.

Etiquetas:

| Tipo | Área | Prioridad | Estado |
|---|---|---|---|
| `bug`, `enhancement`, `documentation`, `question` | `area:skills`, `area:subagentes`, `area:hooks`, `area:esqueleto`, `area:plantillas`, `area:ci` | `prioridad:alta`, `prioridad:media`, `prioridad:baja` | `needs-triage`, `good first issue`, `help wanted`, `breaking-change` |

Prioridades:

| Prioridad | Cuándo |
|---|---|
| `prioridad:alta` | Bloquea el uso en producción, da resultados incorrectos o pierde datos. Se atiende antes que cualquier otra cosa |
| `prioridad:media` | Mejora importante o riesgo conocido, sin bloquear el uso |
| `prioridad:baja` | Conveniente; cuando haya tiempo. Buen punto de entrada junto con `good first issue` |

Los issues nuevos entran con `needs-triage`. Al revisarlos se añaden tipo, área y prioridad, y se quita `needs-triage`. Para elegir en qué trabajar, filtra por prioridad: [alta](https://github.com/rcronald/agentic-harness/issues?q=is%3Aopen+label%3Aprioridad%3Aalta), [media](https://github.com/rcronald/agentic-harness/issues?q=is%3Aopen+label%3Aprioridad%3Amedia), [baja](https://github.com/rcronald/agentic-harness/issues?q=is%3Aopen+label%3Aprioridad%3Abaja). Un PR cierra su issue con `Closes #<número>` en la descripción.

## 6. Ramas

Formato:

```
<tipo>/<número-de-issue>-<descripción-corta>
```

- `<tipo>`: el mismo que el commit principal (ver [tipos](#tipos)).
- `<número-de-issue>`: obligatorio si existe issue; se omite en cambios menores sin issue.
- `<descripción-corta>`: minúsculas, palabras separadas por guiones, sin acentos, 2 a 5 palabras.

Ejemplos:

```
feat/12-skill-deploy
fix/15-hook-jq-windows
docs/guia-y-contribucion
ci/actualizar-actions
```

Ramas especiales: `main` (siempre publicable y protegida) y ramas `dependabot/…` u otras automáticas. La CI rechaza ramas de PR que no sigan el formato.

## 7. Commits

Seguimos [Conventional Commits 1.0](https://www.conventionalcommits.org/es/v1.0.0/):

```
<tipo>(<ámbito>)!: <descripción>

<cuerpo opcional: qué y por qué, no cómo>

<pies opcionales: Closes #12, BREAKING CHANGE: …, Co-Authored-By: …>
```

Reglas:
- **Descripción** en español, en imperativo ("añade", "corrige", no "añadido"), empieza en minúscula, sin punto final y con un máximo de 72 caracteres en la primera línea.
- **Ámbito** opcional pero recomendado, de la lista de abajo.
- **`!`** tras el tipo o el ámbito, y un pie `BREAKING CHANGE: <qué cambia y cómo migrar>`, cuando el cambio rompe compatibilidad.
- **Cuerpo** cuando el porqué no es obvio. Separado por una línea en blanco y con líneas de 72 caracteres como máximo.
- **Un cambio lógico por commit**: no mezcles una corrección con una refactorización.

### Tipos

| Tipo | Uso | Efecto en la versión |
|---|---|---|
| `feat` | Funcionalidad nueva para quien usa el plugin | MENOR |
| `fix` | Corrección de un error | PARCHE |
| `perf` | Mejora de rendimiento | PARCHE |
| `docs` | Solo documentación | Ninguno (o PARCHE si se publica) |
| `test` | Pruebas nuevas o corregidas | Ninguno |
| `refactor` | Cambio de código sin cambiar comportamiento | Ninguno |
| `ci` | Workflows y scripts de CI | Ninguno |
| `build` | Dependencias y empaquetado | Según el impacto |
| `chore` | Mantenimiento; `chore(release)` para publicar | Ninguno |
| `revert` | Revierte un commit anterior | Según lo revertido |
| cualquiera con `!` | Rompe compatibilidad | MAYOR |

### Ámbitos

`skills`, `subagentes`, `hooks`, `mcp`, `esqueleto`, `plantillas`, `scripts`, `ci`, `docs`, `release`, `deps`.

### Ejemplos

```
feat(skills): añade skill deploy-check para revisar la imagen antes de desplegar

fix(hooks): permite leer .env.example cuando la ruta contiene espacios

Closes #15
```

```
feat(esqueleto)!: renombra HISTORY_URL a HISTORY_DSN

BREAKING CHANGE: los agentes nuevos leen HISTORY_DSN. En agentes existentes,
renombra la variable en .env y en el despliegue.
```

```
docs: añade guía de uso y normas de contribución
ci: actualiza actions/checkout a v7
chore(release): v1.1.0
```

Como se fusiona con squash, **el título del PR es el que queda en `main`** y la CI comprueba su formato. Aun así, escribe bien los commits de tu rama: facilitan la revisión.

## 8. Pull requests

- **Título**: con el [formato de commit](#7-commits). La CI lo valida.
- **Descripción**: rellena la plantilla. Incluye qué cambia, por qué, cómo lo probaste y `Closes #<issue>`.
- **Tamaño**: mejor varios PR pequeños que uno grande. Si supera unas 400 líneas sin contar plantillas generadas, plantéate dividirlo.
- **Compatibilidad**: si rompe algo, usa `!` en el título, añade la etiqueta `breaking-change` y explica la migración en el CHANGELOG.
- **CI**: debe pasar entera. Si un fallo no tiene que ver con tu cambio, dilo en el PR.
- **Revisión**: responde a cada comentario con un cambio o una explicación. Quien abrió el comentario lo resuelve.
- **Fusión**: squash merge, y se borra la rama.

## 9. Qué probar según lo que cambies

| Cambias | Ejecuta |
|---|---|
| Hooks, `init-project.sh`, `scaffold-agent.sh` | `scripts/test-hooks.sh` |
| `templates/agent/` o `templates/project/` | `scripts/test-skeleton.sh` (con `HISTORY_TEST_POSTGRES_URL` si tocas el histórico) |
| Manifiestos, skills o subagentes | `claude plugin validate plugins/agentic-harness` y `claude plugin validate .` |
| Versión o CHANGELOG | `scripts/check-version.sh` |
| Workflows | `uvx --from actionlint-py actionlint .github/workflows/*.yml` |
| Skills o subagentes (comportamiento) | Pruébalos en un proyecto real con `claude --plugin-dir plugins/agentic-harness` y describe el resultado en el PR |

Para probar Postgres en local:

```bash
docker run -d --name pg-test -e POSTGRES_PASSWORD=pgtest -p 15432:5432 postgres:17
HISTORY_TEST_POSTGRES_URL="postgresql://postgres:pgtest@localhost:15432/postgres?sslmode=disable" \
  scripts/test-skeleton.sh
docker rm -f pg-test
```

## 10. Guía de estilo

- **Idioma**: español para documentación, mensajes al usuario, prompts y nombres de dominio del esqueleto. Inglés para palabras clave de los frameworks y tipos de commit.
- **Python** (esqueleto): `ruff` con la configuración de `templates/project/ruff.toml`, type hints en funciones públicas y Pydantic para esquemas.
- **Bash** (scripts y hooks): `set -u` o `set -euo pipefail`, compatible con bash de macOS y Linux. Los hooks de seguridad bloquean cuando no pueden leer la entrada.
- **Skills y subagentes**: frontmatter con `name` y `description`. La descripción dice qué hace la skill y cuándo usarla, porque Claude Code la usa para decidir cuándo activarla. Las rutas internas usan `${CLAUDE_PLUGIN_ROOT}` y los nombres llevan prefijo (`agentic-harness:<subagente>`, `mcp__plugin_agentic-harness_<servidor>__<tool>`).
- **Reglas**: si cambias una regla de `templates/project/.claude/rules/`, revisa las skills y subagentes que la citan.
- **Secretos**: nunca en código, pruebas, ejemplos ni logs. Las variables nuevas van a `templates/project/.env.example` con un comentario.

## 11. Versiones y releases

Versionado semántico; el criterio completo y el proceso de publicación están en [CLAUDE.md](CLAUDE.md#versiones-y-publicación). En resumen:

- Los cambios se acumulan en `[Sin publicar]` del [CHANGELOG](CHANGELOG.md). No se sube la versión en cada PR.
- Al publicar: se decide la subida según los tipos de commit acumulados, se actualizan el CHANGELOG y los manifiestos en la rama `chore/release-vX.Y.Z`, se fusiona el PR `chore(release): vX.Y.Z` y se etiqueta ese commit de `main` con `vX.Y.Z`. El workflow `release.yml` crea la release de GitHub.

## 12. Seguridad

**No abras un issue público para una vulnerabilidad.** Repórtala de forma privada desde la pestaña [Security → Report a vulnerability](https://github.com/rcronald/agentic-harness/security/advisories/new). Incluye cómo reproducirla y su impacto. Responderemos antes de publicar ningún detalle.
