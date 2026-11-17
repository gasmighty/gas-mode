<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="./assets/banner-dark.svg">
    <img src="./assets/banner-light.svg" alt="gas-mode: una fábrica de código verificado para Claude Code" width="100%">
  </picture>
</p>

<p align="center">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/licencia-MIT-2f81f7" alt="Licencia MIT"></a>
  <a href="https://claude.com/claude-code"><img src="https://img.shields.io/badge/Claude_Code-skills-D97757" alt="Skills para Claude Code"></a>
  <img src="https://img.shields.io/badge/idioma-espa%C3%B1ol-59636e" alt="En español">
</p>

# gas-mode

Skill orquestadora para Claude Code. Opus planifica, verifica y revisa; Sonnet implementa en un subagente. Entre cada etapa hay un gate de verificación, y cada commit registra qué se verificó.

```text
/gas-mode el job diario de ventas duplica filas cuando se reintenta
```

## Por qué

Un agente que implementa y se autoevalúa en el mismo contexto tiende a:

- dar por terminado un cambio que compila pero nunca se ejecutó;
- parchear el síntoma (guard, retry, `try/except` que traga el error) en lugar de la causa;
- relajar un test o agregar un `ignore` para que el check pase;
- sumar abstracciones que el problema no necesita.

`gas-mode` separa roles para que quien implementa no sea quien aprueba, y exige evidencia de ejecución antes de cada commit.

## Flujo

```mermaid
flowchart LR
    T([Pedido]) --> C[Clasificar<br/>Opus]
    C --> P[Planificar<br/>Opus]
    P --> B[Implementar<br/>Sonnet]
    B --> V{Verificar<br/>Opus}
    V -- ok --> R{Revisar<br/>Opus}
    V -- falla --> B
    R -- hallazgo --> B
    R -- ok --> D([Commit +<br/>Verificado:])
    V -. 3 fallas .-> H([Escala al usuario])
```

| Etapa | Rol | Output |
|---|---|---|
| Clasificar | Opus | Objetivo, cambio mínimo y playbook. |
| Planificar | Opus | Plan en `Docs/`: tareas atómicas, firmas y criterio de verificación por tarea. |
| Implementar | Sonnet | Diff según el plan. Sin permiso para modificar checks existentes. |
| Verificar | Opus | Typecheck, lint, tests y ejecución real (Playwright, queries, `curl` al servicio, harness de eval). |
| Revisar | Opus | Diff contra plan y principios. Revisión adversarial en cambios de riesgo. |
| Commit | Opus | Commit con línea `Verificado:`. Push solo con confirmación. |

Lazo de corrección: hasta 2 iteraciones de Sonnet; a la tercera falla se detiene y reporta el diagnóstico. Opus solo edita código en cambios triviales (un archivo, ~10 líneas, sin lógica nueva).

## Reglas

- **Causa raíz.** Un guard, retry o error tragado no cuenta como fix si el estado que maneja no es legítimo. Dos fixes fallidos con la misma premisa obligan a testear la premisa.
- **Checks inmutables.** El diff no puede modificar ni debilitar tests existentes, config de lint o tipos, la skill `verify` ni workflows de CI (skip, aserciones más laxas, `any`, `noqa`, `@ts-ignore`). Opus revisa esos archivos por separado.
- **Sin flaky.** Prohibido `skip`, `sleep` o reintentar hasta que pase. Se busca la causa (orden, estado compartido, tiempo, seeds).
- **Evidencia en el commit.** El cuerpo termina con `Verificado: typecheck OK, 42 tests OK, journey checkout OK`, o `Verificado: ninguno`.
- **Correcciones → enforcement.** Cada corrección del usuario se convierte en el mecanismo más fuerte posible (arquitectura > tipos/lint > test > docs), se prueba contra el error original y se registra en `## Reglas impuestas` del CLAUDE.md del proyecto. Lo que requiere permiso (dependencia nueva, cambio de esquema, CI) se propone con el diff exacto.
- **Idempotencia y costo.** Pipelines y jobs deben converger si se re-ejecutan. Queries de BigQuery con `--dry_run` previo y umbral de costo; corridas de LLM con estimación previa.

## Instalación

Requisitos: Claude Code, `git`, `gh`, MCP de Playwright. Según el playbook: `bq`, `gcloud`, Node 18+.

```bash
git clone https://github.com/gasmighty/gas-mode.git ~/gas-mode

mkdir -p ~/.claude/skills ~/.claude/commands ~/.claude/shared
for s in gas-mode reflect correct interrogate create-verification-skill; do
  ln -sfn ~/gas-mode/skills/$s ~/.claude/skills/$s
done
ln -sf ~/gas-mode/commands/plan-simple.md ~/.claude/commands/plan-simple.md
ln -sf ~/gas-mode/shared/plan-delegar.md ~/.claude/shared/plan-delegar.md
```

Las skills se referencian por ruta absoluta en `~/.claude`. Reiniciá la sesión para que se registren.

Opcional, para el playbook de CI/CD:

```bash
npx skills add enesgules/dotfiles@optimise-github-actions -g -y
npx skills add github/awesome-copilot@github-actions-hardening -g -y
```

## Uso

```text
/gas-mode el botón "Guardar" queda deshabilitado con el formulario completo
/gas-mode agregá export a CSV en la tabla de resultados
/gas-mode medí si el prompt v3 del clasificador mejora precisión sin subir costo
/gas-mode el build de Cloud Run falla desde ayer
```

`disable-model-invocation: true`: el modelo no lo activa solo. Queda en contexto durante la tarea; invocalo de nuevo para otra tarea, tras `/clear` o en sesión nueva.

<details>
<summary><b>Playbooks</b></summary>
<br>

| Playbook | Alcance |
|---|---|
| [Investigación](./skills/gas-mode/playbooks/investigacion.md) | Solo lectura. Explicación con referencias a código e historial de git. |
| [Bug fix](./skills/gas-mode/playbooks/bug-fix.md) | Repro, causa raíz por descarte, test que falla primero, fix. |
| [Feature](./skills/gas-mode/playbooks/feature.md) | Modelo de datos y firmas primero; boceto de arquitectura si cruza módulos. |
| [Refactor](./skills/gas-mode/playbooks/refactor.md) | Test de caracterización antes de mover estructura; migrar llamadores y borrar la API vieja en el mismo cambio. |
| [Perf](./skills/gas-mode/playbooks/perf.md) | Baseline, una mejora por iteración, misma medición antes y después. |
| [Prototipo](./skills/gas-mode/playbooks/prototipo.md) | Variantes descartables en un scratch dir para resolver una decisión. |
| [Datos](./skills/gas-mode/playbooks/datos.md) | Contrato de grano y clave, `--dry_run`, validación con `SELECT` sin materializar, idempotencia. |
| [IA / Eval](./skills/gas-mode/playbooks/ia-eval.md) | Golden set, harness congelado, juez LLM ciego, costo y latencia p50/p95. |
| [Deploy GCP](./skills/gas-mode/playbooks/deploy-gcp.md) | Diagnóstico read-only en Cloud Build y Cloud Run; IAM solo aditivo; verificación post-deploy. |
| [CI/CD](./skills/gas-mode/playbooks/ci-cd.md) | Minutos facturados por job, checks requeridos, `actionlint`, revisión de seguridad, re-medición. |

</details>

<details>
<summary><b>Skills</b></summary>
<br>

| Skill | Función |
|---|---|
| [`/gas-mode`](./skills/gas-mode/SKILL.md) | Orquestador. Punto de entrada. |
| [`/interrogate`](./skills/interrogate/SKILL.md) | Subagentes adversarios intentan romper un diff; solo sobreviven hallazgos reproducidos con un comando. |
| [`/create-verification-skill`](./skills/create-verification-skill/SKILL.md) | Genera `.claude/skills/verify-<app>/` con launch, doctor, recetas por feature y captura de evidencia. |
| [`/correct`](./skills/correct/SKILL.md) | Analiza commits, reverts y reviews; convierte errores recurrentes en checks. |
| [`/reflect`](./skills/reflect/SKILL.md) | Propone ediciones a skills y CLAUDE.md a partir de la sesión. |

</details>

<details>
<summary><b>Principios</b></summary>
<br>

| Grupo | Principios |
|---|---|
| Base | `laziness-protocol`, `foundational-thinking`, `redesign-from-first-principles`, `attack-the-premise`, `subtract-before-you-add`, `minimize-reader-load`, `exhaust-the-design-space` |
| Arquitectura | `model-the-domain`, `boundary-discipline`, `type-system-discipline`, `migrate-callers-then-delete-legacy-apis`, `separate-before-serializing-shared-state`, `make-operations-idempotent` |
| Verificación | `prove-it-works`, `fix-root-causes`, `sequence-verifiable-units`, `test-behavior-not-implementation`, `explain-the-number` |
| Delegación | `guard-the-context-window` |
| Meta | `proponer-determinismo` |

Un archivo por principio en [`principles/`](./skills/gas-mode/principles/). Se leen bajo demanda y la respuesta final cita los que cambiaron una decisión.

</details>

## Permisos

| Sin confirmación | Con confirmación | Nunca |
|---|---|---|
| Lectura, tests, typecheck, lint, build | `git push` | `merge`, `rebase`, `push --force` |
| Plan y subagentes Sonnet | Slack, Jira, mail, comentarios en PRs | `reset`, `restore`, `clean` |
| Playwright | Dependencias nuevas, recursos de cloud | Escrituras en bases de datos |
| `git commit` tras verificar | Costo sobre umbral | |

El CLAUDE.md del usuario tiene precedencia. Umbrales y permisos se configuran en [`SKILL.md`](./skills/gas-mode/SKILL.md).

## Créditos y licencia

Basado en [pstack](https://github.com/cursor/plugins/tree/main/pstack), de Lauren Tan, y en el artículo [How the Claude Code team thinks about verification](https://claude.dev/blog/how-the-claude-code-team-thinks-about-verification/).

MIT. Ver [`LICENSE`](./LICENSE).
