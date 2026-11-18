#!/bin/bash

if ! command -v jq >/dev/null 2>&1; then
  echo "gas-mode: jq no esta instalado; guard-checks.sh no puede revisar ediciones." >&2
  exit 0
fi

file_path=$(jq -r '.tool_input.file_path // empty')
[[ -z "$file_path" || ! -e "$file_path" ]] && exit 0

check_patterns=(
  '(^|/)(tests?|__tests__|spec)/'
  '\.(test|spec)\.[jt]sx?$'
  '(^|/)test_[^/]*\.py$'
  '_test\.(py|go)$'
  '__snapshots__/'
  '\.snap$'
  '(^|/)\.eslintrc'
  '(^|/)eslint\.config\.'
  '(^|/)tsconfig[^/]*\.json$'
  '(^|/)pyproject\.toml$'
  '(^|/)\.sqlfluff$'
  '\.claude/skills/verify-'
  '\.github/workflows/'
)

for pattern in "${check_patterns[@]}"; do
  if [[ "$file_path" =~ $pattern ]]; then
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: "gas-mode: este archivo es un check existente. Solo se modifica si el plan lo pide con su motivo."
      }
    }'
    exit 0
  fi
done

exit 0
