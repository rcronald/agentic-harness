#!/usr/bin/env bash
# Comprueba las convenciones de CONTRIBUTING.md.
#   scripts/check-conventions.sh title "<título de PR o primera línea de commit>"
#   scripts/check-conventions.sh branch "<nombre de rama>"
#   scripts/check-conventions.sh commit-msg <archivo>   (lo usa el hook commit-msg de git)
set -uo pipefail

TYPES='feat|fix|perf|docs|test|refactor|ci|build|chore|revert'
SCOPES='skills|subagentes|hooks|mcp|esqueleto|plantillas|scripts|ci|docs|release|deps'

check_title() {
  local t=$1 errors=()
  if ! [[ "$t" =~ ^($TYPES)(\(([a-z-]+)\))?(!)?:\ (.+)$ ]]; then
    echo "Formato inválido: '$t'"
    echo "Esperado: <tipo>(<ámbito>)!: <descripción>  con tipo en: ${TYPES//|/, }"
    return 1
  fi
  local scope=${BASH_REMATCH[3]} desc=${BASH_REMATCH[5]}
  if [ -n "$scope" ] && ! [[ "$scope" =~ ^($SCOPES)$ ]]; then
    errors+=("ámbito '$scope' desconocido; usa uno de: ${SCOPES//|/, }")
  fi
  [ "${#t}" -le 72 ] || errors+=("la primera línea tiene ${#t} caracteres (máximo 72)")
  [[ "$desc" =~ ^[[:upper:]ÁÉÍÓÚÑ] ]] && errors+=("la descripción debe empezar en minúscula")
  [[ "$desc" == *. ]] && errors+=("la descripción no debe terminar en punto")
  [[ "$desc" =~ ^[[:space:]] ]] && errors+=("sobra un espacio tras ':'")
  if [ "${#errors[@]}" -gt 0 ]; then
    echo "Título: '$t'"
    printf -- '- %s\n' "${errors[@]}"
    return 1
  fi
  echo "ok título: $t"
}

check_branch() {
  local b=$1
  case "$b" in
    main|dependabot/*|renovate/*) echo "ok rama: $b"; return 0 ;;
  esac
  if [[ "$b" =~ ^($TYPES)/([0-9]+-)?[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "ok rama: $b"
    return 0
  fi
  echo "Rama inválida: '$b'"
  echo "Esperado: <tipo>/<issue>-<descripcion-corta>, p. ej. feat/12-skill-deploy o docs/guia-de-uso"
  return 1
}

check_commit_msg() {
  local first
  first=$(grep -v '^#' "$1" | head -1)
  # Mensajes que genera git y que no se escriben a mano
  case "$first" in
    Merge\ *|Revert\ \"*|fixup!\ *|squash!\ *|amend!\ *) return 0 ;;
  esac
  check_title "$first"
}

case "${1:-}" in
  title) check_title "${2:?falta el título}" ;;
  branch) check_branch "${2:?falta la rama}" ;;
  commit-msg) check_commit_msg "${2:?falta el archivo}" ;;
  *) echo "Uso: $0 title|branch|commit-msg <valor>"; exit 2 ;;
esac
