#!/bin/bash
set -e
git init -q -b main
git config user.email eval@example.com
git config user.name eval
printf 'def suma(a, b):\n    return a - b\n' > calc.py
printf 'from calc import suma\n\n\ndef test_suma():\n    assert suma(2, 3) == 5\n' > test_calc.py
git add . && git commit -qm "init"
git switch -q -c fix-suma
