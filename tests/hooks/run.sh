#!/bin/bash
set -u

root=$(cd "$(dirname "$0")/../.." && pwd)
guard_bash="$root/scripts/hooks/guard-bash.sh"
guard_checks="$root/scripts/hooks/guard-checks.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

failures=0

report() {
  local status=$1 name=$2 detail=$3
  if [[ "$status" == OK ]]; then
    echo "OK    $name"
  else
    echo "FAIL  $name ($detail)"
    failures=$((failures + 1))
  fi
}

bash_case() {
  local expected=$1 cwd=$2 command=$3
  jq -n --arg command "$command" --arg cwd "$cwd" '{tool_name: "Bash", cwd: $cwd, tool_input: {command: $command}}' \
    | "$guard_bash" >/dev/null 2>&1
  local actual=$?
  if [[ "$actual" == "$expected" ]]; then
    report OK "bash [$expected] $command" ""
  else
    report FAIL "bash [$expected] $command" "salio con $actual"
  fi
}

edit_case() {
  local expected=$1 tool=$2 file_path=$3
  local output
  output=$(jq -n --arg tool "$tool" --arg file_path "$file_path" '{tool_name: $tool, tool_input: {file_path: $file_path}}' \
    | "$guard_checks")
  local actual=allow
  [[ "$output" == *'"ask"'* ]] && actual=ask
  if [[ "$actual" == "$expected" ]]; then
    report OK "$tool [$expected] ${file_path#"$work"/}" ""
  else
    report FAIL "$tool [$expected] ${file_path#"$work"/}" "devolvio $actual"
  fi
}

repo="$work/repo"
git init -q -b main "$repo"
git -C "$repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
git -C "$repo" branch feat

bash_case 2 "$repo" "git rebase main"
bash_case 2 "$repo" "git -C /tmp/x merge feat"
bash_case 2 "$repo" "git reset --hard HEAD~1"
bash_case 2 "$repo" "git restore ."
bash_case 2 "$repo" "git clean -fd"
bash_case 2 "$repo" "git checkout -- src/app.py"
bash_case 2 "$repo" "git commit --amend -m x"
bash_case 2 "$repo" "git push --force origin feat"
bash_case 2 "$repo" "git push -f origin feat"
bash_case 0 "$repo" "git push origin feat"
bash_case 0 "$repo" "git status"
bash_case 0 "$repo" "git log --oneline --grep=rebase"
bash_case 0 "$repo" "git checkout feat"
bash_case 2 "$repo" "git commit -m x"
bash_case 2 "$repo" "git add . && git commit -m x"

git -C "$repo" switch -q feat
bash_case 0 "$repo" "git commit -m x"
bash_case 0 "$repo" "git add . && git commit -m 'fix merge of rows'"

bash_case 2 "$repo" "bq query --use_legacy_sql=false 'MERGE ds.t USING ds.s ON t.id = s.id WHEN MATCHED THEN DELETE'"
bash_case 2 "$repo" "bq query --nouse_legacy_sql 'insert into ds.t select 1'"
bash_case 0 "$repo" "bq query --dry_run --use_legacy_sql=false 'MERGE ds.t USING ds.s ON t.id = s.id WHEN MATCHED THEN DELETE'"
bash_case 0 "$repo" "bq query --use_legacy_sql=false 'SELECT created_at, updated_by FROM ds.t'"
bash_case 2 "$repo" "bq mk --table ds.t"
bash_case 2 "$repo" "bq load ds.t gs://b/f.csv"
bash_case 0 "$repo" "bq show --schema ds.t"
bash_case 2 "$repo" "dbt run --select model"
bash_case 2 "$repo" "dbt build"
bash_case 0 "$repo" "dbt compile --select model"
bash_case 0 "$repo" "dbt test --select model"

bash_case 2 "$repo" "git -c x=y rebase main"
bash_case 2 "$repo" "git --no-pager reset --hard"
bash_case 2 "$repo" "git --git-dir .git -c a=b clean -fd"
bash_case 2 "$repo" "git push origin +feat"
bash_case 2 "$repo" "git push -uf origin feat"
bash_case 2 "$repo" "git push --mirror origin"
bash_case 0 "$repo" "git push -u origin feat"
bash_case 0 "$repo" "git push --follow-tags origin feat"
bash_case 2 "$repo" "git checkout HEAD -- ."
bash_case 2 "$repo" "git checkout ."
bash_case 2 "$repo" "git checkout -f feat"
bash_case 2 "$repo" "git status && git checkout ."
bash_case 0 "$repo" "git checkout -b nueva"
bash_case 0 "$repo" "git checkout main && git log -1"
bash_case 2 "$repo" "git switch --discard-changes main"
bash_case 0 "$repo" "git switch -c otra"

printf 'DELETE FROM ds.t WHERE true\n' > "$repo/delete.sql"
printf 'SELECT 1\n' > "$repo/select.sql"
bash_case 2 "$repo" "bq query --destination_table=ds.t 'select 1'"
bash_case 2 "$repo" "bq query --replace --destination_table ds.t 'select 1'"
bash_case 2 "$repo" "bq query --nouse_legacy_sql < delete.sql"
bash_case 2 "$repo" "bq query < no-existe.sql"
bash_case 0 "$repo" "bq query --nouse_legacy_sql < select.sql"
bash_case 0 "$repo" "bq query --dry_run < delete.sql"
bash_case 2 "$repo" "cat delete.sql | bq query"
bash_case 2 "$repo" "bq query 'SELECT 1 -- --dry_run; DELETE FROM ds.t WHERE true'"
bash_case 0 "$repo" "bq query --nouse_legacy_sql 'SELECT a FROM ds.t WHERE a < 5'"
bash_case 0 "$repo" "bq query 'SELECT 1' | head"
bash_case 2 "$repo" "bq --project_id p --location=US rm -f ds.t"
bash_case 2 "$repo" "bq --project_id=p query 'delete from ds.t where true'"
bash_case 2 "$repo" "dbt run-operation drop_all"
bash_case 2 "$repo" "dbt retry"
bash_case 0 "$repo" "dbt ls --select model"

mkdir -p "$work/tests" "$work/src" "$work/.github/workflows"
touch "$work/tests/test_x.py" "$work/src/app.py" "$work/src/app.test.ts" "$work/tsconfig.json" "$work/.github/workflows/ci.yml"

edit_case ask Edit "$work/tests/test_x.py"
edit_case ask Edit "$work/src/app.test.ts"
edit_case ask Write "$work/tsconfig.json"
edit_case ask Edit "$work/.github/workflows/ci.yml"
edit_case allow Write "$work/tests/test_nuevo.py"
edit_case allow Edit "$work/src/app.py"

mkdir -p "$work/e2e"
for config in package.json jest.config.ts vitest.config.mts playwright.config.ts conftest.py pytest.ini setup.cfg ruff.toml mypy.ini .prettierrc.json biome.json .golangci.yml .pre-commit-config.yaml e2e/login.ts; do
  touch "$work/$config"
  edit_case ask Edit "$work/$config"
done
touch "$work/README.md"
edit_case allow Edit "$work/README.md"

echo
if [[ "$failures" -gt 0 ]]; then
  echo "$failures caso(s) fallaron"
  exit 1
fi
echo "Todos los casos pasaron"
