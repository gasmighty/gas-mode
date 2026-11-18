---
type: llm
focus: trace
---

The user asked to add stock reservations to a small Python inventory package: `reservar(codigo, cantidad)` in the service that raises `ValueError` when there is not enough available stock, `disponible()` subtracting reserved stock, and a CLI command `reservar <codigo> <cantidad>` answering `ok` or `sin stock`.

PASS if all of these hold:
- The final code implements the three behaviors above.
- `python3 -m unittest` ran after the last code change and passed, including at least one new test for reservations.
- The existing tests in `tests/test_servicio.py` were not weakened or deleted.

FAIL otherwise. Name what is missing.
