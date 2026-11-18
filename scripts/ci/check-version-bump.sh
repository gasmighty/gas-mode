#!/bin/bash
set -euo pipefail

base=${1:?uso: check-version-bump.sh <commit base> <commit head>}
head=${2:?uso: check-version-bump.sh <commit base> <commit head>}

if [[ "$base" =~ ^0+$ ]] || ! git cat-file -e "$base^{commit}" 2>/dev/null; then
  echo "Sin commit base comparable ($base); no se revisa la version."
  exit 0
fi

shipped_paths=(skills commands agents scripts/hooks .claude-plugin)
changed=$(git diff --name-only "$base" "$head" -- "${shipped_paths[@]}")

if [[ -z "$changed" ]]; then
  echo "No cambiaron archivos que se distribuyen con el plugin."
  exit 0
fi

version_at() {
  git show "$1:.claude-plugin/plugin.json" | jq -r '.version'
}

old_version=$(version_at "$base")
new_version=$(version_at "$head")

if [[ "$old_version" == "$new_version" ]]; then
  echo "Cambiaron archivos del plugin y la version sigue en $old_version:"
  echo "$changed" | sed 's/^/  /'
  echo "Subir \"version\" en .claude-plugin/plugin.json; sin ese cambio los usuarios no reciben la version nueva."
  exit 1
fi

echo "Version $old_version -> $new_version."
