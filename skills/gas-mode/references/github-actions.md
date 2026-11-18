# Workflows de GitHub Actions

Referencia de `SKILL.md`. Aplica en cualquier playbook, no solo en CI/CD.

- **La tarea modifica `.github/workflows/*`:** antes de commitear, revisar los workflows modificados siguiendo `${CLAUDE_PLUGIN_ROOT}/skills/github-actions-hardening/SKILL.md` (leerla por ruta) y aplicar a las lineas tocadas los patrones de eficiencia de `${CLAUDE_SKILL_DIR}/playbooks/ci-cd.md` (`concurrency` con `cancel-in-progress`, cache de dependencias, `timeout-minutes`, path filters). Los hallazgos de seguridad se corrigen dentro de la tarea.
- **La tarea no los modifica:** no crear ni cambiar workflows por iniciativa propia. Si al leerlos aparece algo, proponerlo en una linea al final de la respuesta, sin tocarlo:
  - Riesgo de seguridad (`pull_request_target` que ejecuta codigo de forks, actions de terceros sin pinear a SHA, `permissions` amplios o ausentes, secretos interpolados en `run:`): reportarlo siempre.
  - Desperdicio evidente (sin `concurrency`, sin cache, sin `timeout-minutes`, Windows o macOS sin necesidad): mencionarlo una sola vez por conversacion, con una estimacion.
  - Se agregaron tests o typecheck y el repo no tiene CI: proponer un workflow minimo.
- Si el usuario ya rechazo una propuesta en la conversacion, no repetirla. Si el CLAUDE.md del proyecto dice que no se propongan cambios de CI, respetarlo.
