#!/bin/bash
set -e
git init -q -b main
git config user.email eval@example.com
git config user.name eval
printf 'def saludo():\n    return "hola"\n' > app.py
git add . && git commit -qm "init"
git switch -q -c feat
printf 'def despedida():\n    return "chau"\n' > extra.py
git add . && git commit -qm "feat: despedida"
git switch -q main
printf 'def saludo():\n    return "hola mundo"\n' > app.py
git commit -qam "main: saludo nuevo"
git switch -q feat
