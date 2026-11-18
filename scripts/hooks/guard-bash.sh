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
git_global_opt='((-C|-c|--git-dir|--work-tree|--namespace|--config-env)[[:space:]]+[^[:space:]]+|-[^[:space:]]+)'
git_cmd="git([[:space:]]+${git_global_opt})*[[:space:]]+"
bq_cmd='(^|[^[:alnum:]_-])bq([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+'

for subcommand in merge rebase reset restore clean; do
  if [[ "$command" =~ ${git_cmd}${subcommand}${word_end} ]]; then
    block "git $subcommand esta prohibido. El usuario maneja merge, rebase y descarte de cambios."
  fi
done

checkout_discards_changes() {
  local args=$1 arg
  read -ra words <<<"$args"
  for arg in "${words[@]}"; do
    case "$arg" in
      --|-f|--force|-p|--patch|--theirs|--ours|--merge|-m) return 0 ;;
      -*) continue ;;
    esac
    [[ -e "$cwd/$arg" || -e "$arg" ]] && return 0
  done
  return 1
}

remaining=$command
while [[ "$remaining" =~ ${git_cmd}checkout([^\;\&\|]*)(.*)$ ]]; do
  checkout_args=${BASH_REMATCH[${#BASH_REMATCH[@]}-2]}
  if checkout_discards_changes "$checkout_args"; then
    block "git checkout sobre archivos descarta cambios y esta prohibido. Para cambiar de rama, usar git switch."
  fi
  remaining=${BASH_REMATCH[${#BASH_REMATCH[@]}-1]}
done

if [[ "$command" =~ ${git_cmd}switch[^\;\&\|]*(--discard-changes|--force|[[:space:]]-f${word_end}) ]]; then
  block "git switch con --discard-changes o --force descarta cambios y esta prohibido."
fi

if [[ "$command" =~ ${git_cmd}commit[^\;\&\|]*--amend ]]; then
  block "git commit --amend reescribe historia y esta prohibido. Hacer un commit nuevo."
fi

if [[ "$command" =~ ${git_cmd}push[^\;\&\|]*([[:space:]]--force|[[:space:]]--force-with-lease|[[:space:]]--mirror|[[:space:]]-[[:alpha:]]*f[[:alpha:]]*${word_end}|[[:space:]]\+[^[:space:]]) ]]; then
  block "push forzado prohibido (--force, -f, --mirror o refspec con +)."
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

if [[ "$command" =~ ${bq_cmd}(mk|load|cp|rm|insert|update)${word_end} ]]; then
  block "bq ${BASH_REMATCH[${#BASH_REMATCH[@]}-2]} escribe en BigQuery. Entregar el comando al usuario para que lo corra."
fi

without_quoted_text() {
  local text=$1
  local quoted_re="^([^'\"]*)('[^']*'|\"[^\"]*\")(.*)$"
  while [[ "$text" =~ $quoted_re ]]; do
    text="${BASH_REMATCH[1]} ${BASH_REMATCH[3]}"
  done
  printf '%s' "$text"
}

if [[ "$command" =~ ${bq_cmd}query${word_end} ]]; then
  shell_text=$(without_quoted_text "$command")
  if [[ ! "$shell_text" =~ [[:space:]]--dry_run(=true)?${word_end} ]]; then
    if [[ "$shell_text" =~ [[:space:]]--(destination_table|replace|append_table)([=[:space:]]|$) ]]; then
      block "bq query con --destination_table, --replace o --append_table escribe en BigQuery. Correrla solo con --dry_run y entregar el comando al usuario."
    fi

    sql_text=$command
    if [[ "$shell_text" =~ \|[^\;\&]*bq ]]; then
      block "no se puede revisar una query que llega a bq por un pipe. Pasarla inline o con < archivo, o correrla con --dry_run."
    fi
    if [[ "$shell_text" =~ (^|[^\<])\<[[:space:]]*([^\<[:space:]\;\&\|]+) ]]; then
      sql_file=${BASH_REMATCH[2]}
      [[ "$sql_file" != /* ]] && sql_file="$cwd/$sql_file"
      [[ -r "$sql_file" ]] || block "no se puede leer $sql_file para revisar la query. Correrla con --dry_run."
      sql_text+=$'\n'$(cat "$sql_file")
    fi

    shopt -s nocasematch
    if [[ "$sql_text" =~ (^|[^[:alnum:]_])(insert|update|delete|merge|create|drop|truncate|alter)[[:space:]] ]]; then
      shopt -u nocasematch
      block "la query escribe en BigQuery. Correrla solo con --dry_run y entregar el comando al usuario."
    fi
    shopt -u nocasematch
  fi
fi

if [[ "$command" =~ (^|[^[:alnum:]_-])dbt[[:space:]]+(run-operation|run|build|seed|snapshot|retry)$word_end ]]; then
  block "dbt ${BASH_REMATCH[2]} escribe en el warehouse. Entregar el comando al usuario."
fi

exit 0
