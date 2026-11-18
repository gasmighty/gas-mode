---
runs: 1
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, TodoWrite, Agent]
---

/gas-mode:gas-mode agregá reservas de stock al inventario: `reservar(codigo, cantidad)` en el servicio, que falle con `ValueError` si no hay disponible suficiente; `disponible()` tiene que descontar lo reservado; y un comando `reservar <codigo> <cantidad>` en el CLI que responda `ok` o `sin stock`. Los tests se corren con `python3 -m unittest`.
