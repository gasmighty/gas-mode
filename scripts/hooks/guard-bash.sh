#!/bin/bash

if ! command -v jq >/dev/null 2>&1; then
  echo "gas-mode: jq no esta instalado; guard-bash.sh no puede revisar comandos." >&2
  exit 0
fi

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
[[ -z "$command" ]] && exit 0
[[ -z "$cwd" ]] && cwd=$PWD

block() {
  echo "gas-mode: $1" >&2
  exit 2
}

word_end='([[:space:];&|)]|$)'
git_cmd='git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+'

if [[ "$command" =~ $git_cmd(merge|rebase|reset|restore|clean)$word_end ]]; then
  block "git ${BASH_REMATCH[2]} esta prohibido. El usuario maneja merge, rebase y descarte de cambios."
fi

if [[ "$command" =~ ${git_cmd}checkout[[:space:]]+--$word_end ]]; then
  block "git checkout -- descarta cambios y esta prohibido."
fi

if [[ "$command" =~ ${git_cmd}commit[^\;\&\|]*--amend ]]; then
  block "git commit --amend reescribe historia y esta prohibido. Hacer un commit nuevo."
fi

if [[ "$command" =~ ${git_cmd}push[^\;\&\|]*(--force|--force-with-lease|[[:space:]]-f$word_end) ]]; then
  block "push forzado prohibido."
fi

default_branch() {
  local ref
  ref=$(git -C "$cwd" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
  if [[ -n "$ref" ]]; then
    echo "${ref#origin/}"
    return
  fi
  local candidate
  for candidate in main master; do
    if git -C "$cwd" show-ref --verify --quiet "refs/heads/$candidate"; then
      echo "$candidate"
      return
    fi
  done
}

if [[ "$command" =~ ${git_cmd}commit$word_end ]]; then
  current=$(git -C "$cwd" branch --show-current 2>/dev/null)
  default=$(default_branch)
  if [[ -n "$current" && "$current" == "$default" ]]; then
    block "no se commitea en la rama por defecto ($current). Proponer al usuario crear una rama de trabajo con git switch -c."
  fi
fi

if [[ "$command" =~ (^|[^[:alnum:]_-])bq[[:space:]]+(mk|load|cp|rm|insert|update)$word_end ]]; then
  block "bq ${BASH_REMATCH[2]} escribe en BigQuery. Entregar el comando al usuario para que lo corra."
fi

shopt -s nocasematch
if [[ "$command" =~ (^|[^[:alnum:]_-])bq[[:space:]]+query ]] \
  && [[ "$command" =~ (^|[^[:alnum:]_])(insert|update|delete|merge|create|drop|truncate|alter)[[:space:]] ]] \
  && [[ ! "$command" =~ --dry_run ]]; then
  block "la query escribe en BigQuery. Correrla solo con --dry_run y entregar el comando al usuario."
fi
shopt -u nocasematch

if [[ "$command" =~ (^|[^[:alnum:]_-])dbt[[:space:]]+(run|build|seed|snapshot)$word_end ]]; then
  block "dbt ${BASH_REMATCH[2]} escribe en el warehouse. Entregar el comando al usuario."
fi

exit 0
