# CI/CD

Crear o modificar workflows de GitHub Actions, o mejorar un CI lento o caro. Cada cambio se justifica con una medicion y se vuelve a medir despues. Principios: explain-the-number, prove-it-works, make-operations-idempotent, sequence-verifiable-units.

Skills de apoyo (leerlas por ruta si existen; si no estan, seguir con los pasos de este playbook):

- Costo y velocidad: `~/.claude/skills/optimise-github-actions/SKILL.md` y su script `scripts/measure.mjs`.
- Seguridad: `~/.claude/skills/github-actions-hardening/SKILL.md`.

1. Medir antes de cambiar (solo lectura). Si el repo ya tiene corridas:

   ```bash
   node ~/.claude/skills/optimise-github-actions/scripts/measure.mjs OWNER/REPO --days 14 --out <scratch>/jobs.json
   ```

   Devuelve minutos facturados por workflow y por job, desperdicio por redondeo y cancelaciones, p50 y p90 de duracion y corridas por PR. En un repo publico los runners estandar son gratis: leer los minutos como tiempo, no como costo. Si el repo no tiene CI todavia, saltear este paso.
2. Entender que protege cada job antes de proponer: triggers, `concurrency`, path filters, grafo de `needs:`, checks requeridos (`gh api repos/OWNER/REPO/rulesets` y `gh api repos/OWNER/REPO/branches/<rama>/protection`), tests que leen los archivos de workflow y que usa el deploy (imagenes, artefactos, estado "CI passed"). Renombrar o sacar un check requerido bloquea todos los merges.
3. Proponer una tabla: cambio, minutos ahorrados, tiempo ahorrado y riesgo. Decir para que lado mueve cada cambio: paralelizar baja el tiempo de espera y sube los minutos facturados; unir jobs chicos hace lo contrario. Esperar que el usuario elija.
4. Escribir el plan (plan-simple) con los cambios elegidos, uno por tarea. Delegar a Sonnet segun "Delegacion a Sonnet". Cada cambio no obvio lleva un comentario en el YAML que explica por que (excepcion permitida a la regla de no comentar: es una restriccion que el codigo no puede expresar).
5. Revisar seguridad con github-actions-hardening sobre los workflows modificados (ver "Workflows de GitHub Actions" en SKILL.md).
6. Validar localmente con `actionlint` sobre `.github/workflows/`. Si no esta instalado, preguntar antes de instalarlo (`brew install actionlint`). Correr los tests del repo que leen los workflows.
7. Verificar en GitHub: commitear y pedir confirmacion para hacer push a una rama no protegida (nunca directo a la rama por defecto). Seguir la corrida con `gh run watch` y revisar que los jobs que debian saltearse se salteen y que los que debian correr corran. El primer run de un workflow modificado suele correr todo y es el mas caro: avisarlo antes del push.
8. Volver a medir con el mismo script despues de suficientes corridas y comparar contra el paso 1. Una mejora sin medicion posterior se reporta como estimada, no como medida.

**Respuesta:** minutos y tiempos antes, cambios aplicados con su ahorro estimado, que se verifico en GitHub, hallazgos de seguridad y, si ya hay datos, el ahorro medido.
