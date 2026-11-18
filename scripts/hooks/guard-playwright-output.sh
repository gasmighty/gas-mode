#!/bin/bash

if ! command -v jq >/dev/null 2>&1; then
  echo "gas-mode: jq no esta instalado; guard-playwright-output.sh no puede revisar el .gitignore." >&2
  exit 0
fi

input=$(cat)
cwd=$(jq -r '.cwd // empty' <<<"$input")
filename=$(jq -r '.tool_input.filename // empty' <<<"$input")
workspace=${CLAUDE_PROJECT_DIR:-${cwd:-$PWD}}

repo_root=$(git -C "$workspace" rev-parse --show-toplevel 2>/dev/null) || exit 0
workspace=$(cd "$workspace" 2>/dev/null && pwd -P) || exit 0

default_output_dir="$workspace/.playwright-mcp"
probe_paths=("$default_output_dir/probe")
if [[ -n "$filename" ]]; then
  [[ "$filename" == /* ]] && probe_paths+=("$filename") || probe_paths+=("$workspace/$filename")
fi

blocked=0
for path in "${probe_paths[@]}"; do
  [[ "$path" == "$repo_root"/* ]] || continue
  git -C "$repo_root" check-ignore -q --no-index "${path#"$repo_root"/}" 2>/dev/null && continue
  blocked=1
  if [[ "$path" == "$default_output_dir/probe" ]]; then
    echo "gas-mode: ${default_output_dir#"$repo_root"/}/ no esta en el .gitignore del proyecto. Agregarlo antes de usar Playwright para que screenshots y trazas no entren en un commit." >&2
  else
    echo "gas-mode: ${path#"$repo_root"/} no esta ignorado por git. Guardarlo en un directorio incluido en el .gitignore." >&2
  fi
done

exit $((blocked * 2))
