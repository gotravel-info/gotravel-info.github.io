#!/usr/bin/env bash
# Borra los documentos publicados que llevan más de DIAS sin cambios:
#  - itinerarios interactivos (*.html de la raíz)
#  - carpetas de «Documentos de viaje» (v/<carpeta>/)
# Nunca toca las páginas del sitio ni los ejemplos.
set -euo pipefail
DIAS="${DIAS:-60}"
SIMULAR="${SIMULAR:-false}"
limite=$(( $(date +%s) - DIAS * 86400 ))
fijos=" index.html sw.js checkin.html billetera.html "
borrados=0

ultima_fecha() { git log -1 --format=%ct -- "$1" 2>/dev/null || echo 0; }
borrar() {
  local ruta="$1" t="$2"
  echo "Borra ${ruta} (último cambio: $(date -u -d "@${t}" +%F))"
  borrados=$((borrados + 1))
  if [ "$SIMULAR" != "true" ]; then git rm -r -q -- "$ruta"; fi
}

shopt -s nullglob
for f in *.html; do
  case "$fijos" in *" $f "*) continue ;; esac
  case "$f" in ejemplo-*) continue ;; esac
  t=$(ultima_fecha "$f")
  if [ "${t:-0}" -gt 0 ] && [ "$t" -lt "$limite" ]; then borrar "$f" "$t"; fi
done
for d in v/*/; do
  d="${d%/}"
  t=$(ultima_fecha "$d")
  if [ "${t:-0}" -gt 0 ] && [ "$t" -lt "$limite" ]; then borrar "$d" "$t"; fi
done

echo "Documentos con más de ${DIAS} días: ${borrados}"
echo "borrados=${borrados}" >> "${GITHUB_OUTPUT:-/dev/null}"
if [ "$SIMULAR" = "true" ] || [ "$borrados" -eq 0 ]; then exit 0; fi
git config user.name "Go Travel (limpieza automática)"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git commit -q -m "Limpieza automática: borra ${borrados} documento(s) con más de ${DIAS} días"
git push -q
