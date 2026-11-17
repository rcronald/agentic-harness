# Guía de uso

Esta guía explica, paso a paso, cómo crear y operar un agente de IA con el plugin `agentic-harness`. No hace falta conocer el proyecto de antemano. Si vas a cambiar el propio plugin, lee también [CONTRIBUTING.md](../CONTRIBUTING.md).

## Índice
1. [Qué es y cuándo usarlo](#1-qué-es-y-cuándo-usarlo)
2. [Requisitos](#2-requisitos)
3. [Instalar el plugin](#3-instalar-el-plugin)
4. [Crear tu primer agente](#4-crear-tu-primer-agente)
5. [Qué se genera](#5-qué-se-genera)
6. [Configurar](#6-configurar)
7. [Ejecutar el agente](#7-ejecutar-el-agente)
8. [Adaptar el agente a tu caso](#8-adaptar-el-agente-a-tu-caso)
9. [Evaluar la calidad](#9-evaluar-la-calidad)
10. [Trazas en Langfuse](#10-trazas-en-langfuse)
11. [Histórico, límites y coste](#11-histórico-límites-y-coste)
12. [Pruebas y CI](#12-pruebas-y-ci)
13. [Desplegar](#13-desplegar)
14. [Actualizar el plugin y los agentes existentes](#14-actualizar-el-plugin-y-los-agentes-existentes)
15. [Problemas frecuentes](#15-problemas-frecuentes)

---

## 1. Qué es y cuándo usarlo

`agentic-harness` es un plugin de [Claude Code](https://code.claude.com). Le da a Claude Code el conocimiento, las herramientas y las reglas para construir agentes con:

- **LangChain / LangGraph** como framework de agentes.
- **Claude** (Anthropic) como modelo; por defecto `claude-opus-5-5`.
- **Langfuse** para trazas y evaluaciones.

Úsalo cuando quieras un agente listo para producción sin empezar de cero: el plugin parte de un esqueleto probado que ya resuelve histórico por sesión, límites de coste, aprobación humana de acciones, trazas, CLI, API HTTP, evaluaciones, pruebas, contenedor y CI. Tú describes el caso; Claude Code adapta el esqueleto.

El código generado no depende de ningún proveedor de nube: se empaqueta como un contenedor estándar.

## 2. Requisitos

| Herramienta | Para qué | Comprobar |
|---|---|---|
| [Claude Code](https://code.claude.com) | Ejecuta el plugin | `claude --version` |
| [uv](https://docs.astral.sh/uv/) | Dependencias y ejecución de Python | `uv --version` |
| Python 3.12+ | Lo instala `uv` si falta | `uv python list` |
| `jq` (o `python3`) | Lo usan los hooks de seguridad | `jq --version` |
| Docker o Podman | Opcional, para construir la imagen | `docker --version` |

Cuentas y claves:
- **Anthropic** (`ANTHROPIC_API_KEY`): obligatoria para ejecutar el agente con el modelo real.
- **Langfuse** (`LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`): opcional. Sin ellas, las trazas se desactivan.

## 3. Instalar el plugin

Una sola vez por máquina; queda disponible en todos tus proyectos. Dentro de Claude Code:

```
/plugin marketplace add rcronald/agentic-harness
/plugin install agentic-harness@agentic-harness
```

Reinicia Claude Code. La primera vez te pedirá aprobar los servidores MCP de documentación (`docs-langchain`, `reference-langchain`, `langfuse-docs`): apruébalos, porque Claude Code los consulta antes de escribir código de esas librerías.

Comprueba que está activo con `/plugin` o `claude plugin list`.

## 4. Crear tu primer agente

1. Crea una carpeta vacía (o usa un repositorio existente) y abre Claude Code en ella:
   ```bash
   mkdir ~/code/soporte && cd ~/code/soporte && claude
   ```
2. Pide el agente con la skill `new-agent`. El nombre va en `snake_case` porque será un paquete de Python:
   ```
   /agentic-harness:new-agent soporte "responde dudas de clientes consultando el estado de sus pedidos"
   ```
3. Claude Code:
   1. **Prepara el proyecto** (`init-project`) si es la primera vez: reglas, configuración de `ruff` y `pytest`, `Dockerfile`, CI y `.env.example`.
   2. **Pregunta lo que falte** en un solo mensaje: qué entra y qué sale, qué sistemas toca, qué acciones tienen efectos y cómo se va a usar.
   3. **Diseña** el agente con el subagente `agent-architect`. Si hay acciones con efectos (escribir, enviar, cobrar), te enseña el diseño y espera tu visto bueno.
   4. **Copia el esqueleto** a `agents/soporte/` e instala las dependencias.
   5. **Comprueba** que las pruebas del esqueleto pasan antes de tocar nada.
   6. **Adapta** el prompt, las tools y las pruebas a tu caso.
   7. **Escribe casos de evaluación**, ejecuta `scripts/ci.sh` y pide una revisión al subagente `agent-reviewer`.
4. Al final te dice qué hace el agente, cómo ejecutarlo y qué quedó sin verificar.

Después, configura tus claves (sección 6) y **reinicia Claude Code** para que cargue las reglas de `.claude/rules/`.

## 5. Qué se genera

```
mi-proyecto/
├── CLAUDE.md                 # cómo trabajar en el proyecto (lo lee Claude Code)
├── .claude/
│   ├── rules/                # reglas que Claude Code aplica siempre
│   └── settings.json         # modelo y permisos
├── .github/workflows/ci.yml  # CI en GitHub Actions
├── scripts/ci.sh             # la CI real: lint, formato y pruebas
├── Dockerfile                # imagen estándar para cualquier agente del proyecto
├── ruff.toml · pytest.ini    # estilo y pruebas
├── .env.example              # todas las variables, documentadas
└── agents/
    └── soporte/
        ├── agent.py          # construcción del agente y AgentRunner (chat, decide, clear)
        ├── prompts.py        # system prompt y PROMPT_VERSION
        ├── config.py         # configuración tipada y validada
        ├── memory.py         # histórico por sesión, recorte y backends
        ├── tools.py          # herramientas del agente
        ├── guards.py         # límites, presupuesto de tokens, aprobación humana
        ├── observability.py  # Langfuse
        ├── cli.py            # conversación por terminal
        ├── server.py         # API HTTP
        ├── evals/            # casos de evaluación y script
        └── tests/            # pruebas
```

Puedes tener varios agentes en el mismo proyecto: cada uno es una carpeta en `agents/`.

## 6. Configurar

1. Copia la plantilla y rellena lo que necesites:
   ```bash
   cp .env.example .env
   ```
   Como mínimo, `ANTHROPIC_API_KEY`. Las variables que dejes vacías usan su valor por defecto.
2. Comprueba la configuración sin arrancar el agente:
   ```bash
   uv run python -m agents.soporte.config
   ```
   Si todo es correcto, muestra la configuración efectiva sin enseñar secretos. Si no, lista cada problema y termina con código 2:
   ```
   Configuración inválida de soporte:
     - AGENT_MAX_TOKENS: Input should be a valid integer (valor recibido: 'muchos')
     - ANTHROPIC_API_KEY: falta (necesaria para llamar al modelo)
   ```

Cómo se resuelve cada valor, de mayor a menor prioridad:
1. Variable de entorno del proceso (Docker, CI, gestor de secretos).
2. `.env` del directorio desde el que ejecutas.
3. Valor por defecto de `config.py`.

> Claude Code no lee ni edita `.env`: los hooks del plugin lo bloquean. Lo editas tú.

Las variables más usadas (lista completa en `.env.example`):

| Variable | Por defecto | Qué controla |
|---|---|---|
| `AGENT_MODEL` | `claude-opus-5-5` | Modelo de Claude |
| `AGENT_MAX_TOKENS` | `4096` | Tokens máximos por respuesta |
| `AGENT_DRY_RUN` | `true` | Las tools con efectos simulan la acción |
| `HISTORY_BACKEND` | `memory` | `memory`, `sqlite` o `postgres` |
| `HISTORY_URL` | — | Archivo SQLite o cadena de conexión de Postgres |
| `APP_ENV` | `dev` | Entorno en las trazas (`dev`, `staging`, `prod`) |
| `AGENT_API_TOKEN` | — | Si se define, la API exige `Authorization: Bearer <token>` |

## 7. Ejecutar el agente

### Por terminal

```bash
uv run python -m agents.soporte.cli --session demo
```

Escribe tus mensajes. `/borrar` borra el histórico de la sesión y `/salir` termina. Si el agente quiere ejecutar una acción con efectos, la CLI te pide aprobarla o rechazarla.

### Como API HTTP

```bash
uv run python -m agents.soporte.server        # escucha en el puerto PORT (8000)
```

| Método | Ruta | Uso |
|---|---|---|
| `GET` | `/health` | Comprobación de vida (sin token) |
| `POST` | `/chat` | Envía un mensaje: `{"session_id", "message", "user_id"?}` |
| `GET` | `/sessions/{id}/approvals` | Acciones pendientes de aprobación |
| `POST` | `/sessions/{id}/decisions` | Aprueba o rechaza: `{"decisions": {"<id>": {"type": "approve"}}}` |
| `DELETE` | `/sessions/{id}` | Borra el histórico de la sesión |

Ejemplo de conversación con una aprobación:

```bash
curl -s localhost:8000/chat -H 'content-type: application/json' \
  -d '{"session_id": "cliente-42", "message": "Apunta que el cliente pidió factura"}'
# {"session_id":"cliente-42","status":"needs_approval","reply":null,
#  "pending":[{"id":"<id>","tool":"registrar_nota","args":{...}}]}

curl -s localhost:8000/sessions/cliente-42/decisions -H 'content-type: application/json' \
  -d '{"decisions": {"<id>": {"type": "approve"}}}'
# {"session_id":"cliente-42","status":"completed","reply":"Nota guardada.", "pending":[]}
```

`status` puede ser `completed`, `needs_approval` o `timeout`. El mismo `session_id` mantiene la conversación; otro distinto empieza de cero.

## 8. Adaptar el agente a tu caso

Pídeselo a Claude Code en lenguaje natural; las skills se activan solas, o puedes invocarlas:

| Quieres… | Skill |
|---|---|
| Que el agente haga algo nuevo o conecte una API | `/agentic-harness:add-tool soporte "consultar el estado de un pedido por su número"` |
| Medir la calidad o comparar prompts | `/agentic-harness:add-eval soporte` |
| Revisar o arreglar las trazas | `/agentic-harness:instrument-langfuse soporte` |

Reglas que el plugin aplica al adaptar:
- **Prompt** (`prompts.py`): conserva sus secciones (rol, límites, uso de tools, datos frente a instrucciones, formato, qué hacer si falta información) y sube `PROMPT_VERSION` en cada cambio.
- **Tools** (`tools.py`): una responsabilidad, argumentos tipados, docstring para el modelo y errores como texto.
- **Acciones con efectos**: van en `TOOLS_REQUIRING_APPROVAL`. El agente se detiene y espera una decisión humana antes de ejecutarlas, y con `AGENT_DRY_RUN=true` solo las simula. Pon `AGENT_DRY_RUN=false` cuando quieras que actúen de verdad.

## 9. Evaluar la calidad

Las pruebas comprueban que el código funciona; la evaluación comprueba que el agente **responde bien**. Los casos viven en `agents/soporte/evals/dataset.jsonl`:

```json
{"input": "¿Dónde está mi pedido 123?", "expected_output": "Da el estado real del pedido 123 obtenido con la herramienta.", "metadata": {"expect_tools": ["consultar_pedido"]}}
```

```bash
uv run python -m agents.soporte.evals.run_eval              # evaluadores automáticos
uv run python -m agents.soporte.evals.run_eval --judge      # añade un juez LLM
uv run python -m agents.soporte.evals.run_eval --min-score 0.8   # falla por debajo del umbral
```

Llama al modelo real, así que cuesta dinero. Las acciones con efectos siempre se simulan durante la evaluación. Con claves de Langfuse, cada ejecución queda como experimento con la versión del prompt y el modelo en el nombre, para comparar versiones; sin ellas, se ejecuta en local.

## 10. Trazas en Langfuse

Con `LANGFUSE_PUBLIC_KEY` y `LANGFUSE_SECRET_KEY` definidas (y `LANGFUSE_BASE_URL` si no usas la región por defecto), cada turno genera una traza con: nombre del agente, entorno (`APP_ENV`), versión (`APP_RELEASE`), `session_id`, `PROMPT_VERSION` y modelo. Las conversaciones se agrupan por sesión.

Antes de enviarse, se enmascaran claves de API, correos y números de tarjeta. Amplía los patrones en `observability.py` con los datos sensibles de tu dominio.

## 11. Histórico, límites y coste

| Mecanismo | Variable | Por defecto |
|---|---|---|
| Backend del histórico | `HISTORY_BACKEND` | `memory` (se pierde al reiniciar) |
| Estrategia al crecer | `HISTORY_STRATEGY` | `trim` (recorta lo antiguo); `summarize` lo resume |
| Tamaño máximo del histórico | `HISTORY_MAX_TOKENS` | `12000` |
| Llamadas al modelo por turno | `AGENT_MAX_MODEL_CALLS` | `10` |
| Llamadas a tools por turno | `AGENT_MAX_TOOL_CALLS` | `20` |
| Tiempo máximo por turno | `AGENT_RUN_TIMEOUT_S` | `180` |
| Tokens por sesión | `AGENT_SESSION_TOKEN_BUDGET` | `500000` (`0` = sin límite) |

Elegir backend:
- `memory`: desarrollo y pruebas.
- `sqlite`: un solo proceso en una máquina; `HISTORY_URL` es la ruta del archivo.
- `postgres`: producción y varias réplicas. Instala el extra con `uv add langgraph-checkpoint-postgres "psycopg[binary]"` y pon la cadena de conexión en `HISTORY_URL`.

## 12. Pruebas y CI

```bash
uv run pytest                  # pruebas unitarias (sin modelo real, sin coste)
uv run pytest -m integration   # con el modelo real; usa ANTHROPIC_API_KEY del entorno o de .env
scripts/ci.sh                  # lo mismo que ejecuta la CI: lint, formato y pruebas
scripts/ci.sh --evals          # además, integración y evaluaciones
```

En GitHub, `.github/workflows/ci.yml` ejecuta `scripts/ci.sh` en cada push a `main` y en cada PR. Las evaluaciones se lanzan a mano (**Actions → ci → Run workflow → evals**) y necesitan:
- Un entorno llamado `evals` (**Settings → Environments**) con los secretos `ANTHROPIC_API_KEY`, `LANGFUSE_PUBLIC_KEY` y `LANGFUSE_SECRET_KEY`.
- Opcionalmente, las variables `LANGFUSE_BASE_URL` y `EVAL_MIN_SCORE`.

Si usas otro sistema de CI, haz que ejecute `scripts/ci.sh`.

## 13. Desplegar

```bash
docker build --build-arg AGENT=soporte -t soporte .
docker run --env-file .env -p 8000:8000 soporte
```

La imagen arranca la API HTTP con un usuario sin privilegios y no incluye `.env`: las variables se inyectan al ejecutarla. En cualquier entorno expuesto:
- Define `AGENT_API_TOKEN`.
- Usa `HISTORY_BACKEND=postgres` si hay más de una réplica.
- Decide `AGENT_DRY_RUN=false` de forma explícita. Con `APP_ENV=prod` y el modo prueba activo, el agente no arranca para evitar que finjas acciones en producción.

## 14. Actualizar el plugin y los agentes existentes

```bash
claude plugin marketplace update agentic-harness
claude plugin update agentic-harness@agentic-harness
```

Reinicia Claude Code después.

Importante: el esqueleto **se copia** al crear un agente, así que actualizar el plugin no modifica agentes ya creados. Cada versión del [CHANGELOG](../CHANGELOG.md) indica si hay cambios que conviene aplicar a mano y cómo.

Las reglas de `.claude/rules/` también se copiaron al proyecto. Para traer las nuevas sin perder tus cambios, ejecuta `/agentic-harness:init-project`: no sobrescribe nada y te propone cómo combinar lo que difiera.

## 15. Problemas frecuentes

**Claude Code dice que no puede leer `.env`.** Es intencionado: los hooks protegen los secretos. Edita `.env` tú y usa `uv run python -m agents.<nombre>.config` para comprobarlo.

**Todas las herramientas aparecen bloqueadas** con "El hook de seguridad no pudo leer la llamada". Faltan `jq` y `python3`. Instala `jq` (`brew install jq`, `apt install jq`) y reinicia.

**No aparecen las skills `/agentic-harness:…`.** Reinicia Claude Code tras instalar o actualizar, y comprueba con `claude plugin list` que el plugin está `enabled`.

**El agente no arranca: "Configuración inválida".** El mensaje dice qué variable falla y por qué. Corrige `.env` o el entorno.

**Las pruebas de integración aparecen como `skipped`.** No hay `ANTHROPIC_API_KEY` ni en el entorno ni en `.env`.

**El agente olvida la conversación al reiniciar.** Usas `HISTORY_BACKEND=memory`. Cambia a `sqlite` o `postgres`.

**La API responde 401.** Está definido `AGENT_API_TOKEN`: envía `Authorization: Bearer <token>`.

**Una respuesta dice que se alcanzó el límite de uso.** La sesión superó `AGENT_SESSION_TOKEN_BUDGET`. Empieza otra sesión o sube el límite.

¿Algo que no está aquí? Abre un [issue](https://github.com/rcronald/agentic-harness/issues/new/choose).
