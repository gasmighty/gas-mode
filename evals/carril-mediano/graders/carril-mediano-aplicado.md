---
type: llm
focus: trace
arm: with-only
---

The session ran the gas-mode skill on a medium-sized task (reservations across `inventario/servicio.py`, `inventario/cli.py` and tests).

PASS if all of these hold:
- The session said it chose the medium lane ("carril mediano").
- The main session wrote the code itself; no subagent was used to implement.
- No plan file was written under `Docs/`.
- After verifying, the session launched the `gas-mode:revisor` agent (or, if unavailable, a general-purpose subagent with model opus and the reviewer instructions) to review the diff.
- Confirmed reviewer findings, if any, were fixed and verification ran again.

FAIL if any of these does not hold. Name which one.
