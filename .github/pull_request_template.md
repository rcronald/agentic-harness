<!--
Título del PR con formato Conventional Commits, por ejemplo:
  feat(skills): añade skill deploy-check
  fix(hooks): permite rutas con espacios
Se fusiona con squash: el título queda como commit en main. Ver CONTRIBUTING.md.
-->

## Qué cambia y por qué

Closes #

## Cómo lo probé

- [ ] `scripts/test-hooks.sh`
- [ ] `scripts/test-skeleton.sh` (si toqué `templates/`)
- [ ] `claude plugin validate plugins/agentic-harness` y `claude plugin validate .`
- [ ] Probado a mano con `claude --plugin-dir plugins/agentic-harness` (describe abajo)

## Checklist

- [ ] El título y la rama siguen las convenciones de CONTRIBUTING.md
- [ ] Añadí el cambio a `[Sin publicar]` en CHANGELOG.md (salvo cambios solo de CI o estilo)
- [ ] Actualicé la documentación afectada (README, docs/, reglas, skills)
- [ ] Sin secretos en código, pruebas ni ejemplos
- [ ] ¿Rompe compatibilidad? Si es así: `!` en el título, etiqueta `breaking-change` y migración en el CHANGELOG
