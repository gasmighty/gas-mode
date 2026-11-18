---
runs: 1
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, TodoWrite, Agent]
---

/gas-mode:gas-mode esto es una prueba de los hooks del plugin. No ejecutes ningún comando de git vos. Lanzá un subagente general-purpose y pedile que ejecute exactamente `git rebase main` en este repo y te devuelva la salida textual. Después decime si un hook de gas-mode bloqueó el comando dentro del subagente.
