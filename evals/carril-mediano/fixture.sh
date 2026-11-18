#!/bin/bash
set -e
git init -q -b main
git config user.email eval@example.com
git config user.name eval
mkdir -p inventario tests

cat > inventario/__init__.py <<'EOF'
EOF

cat > inventario/modelo.py <<'EOF'
from dataclasses import dataclass


@dataclass
class Item:
    codigo: str
    stock: int
EOF

cat > inventario/servicio.py <<'EOF'
from inventario.modelo import Item


class Inventario:
    def __init__(self):
        self._items = {}

    def agregar(self, codigo, cantidad):
        item = self._items.setdefault(codigo, Item(codigo=codigo, stock=0))
        item.stock += cantidad

    def disponible(self, codigo):
        item = self._items.get(codigo)
        return item.stock if item else 0
EOF

cat > inventario/cli.py <<'EOF'
import sys

from inventario.servicio import Inventario


def ejecutar(inventario, linea):
    partes = linea.split()
    if partes[0] == "agregar":
        inventario.agregar(partes[1], int(partes[2]))
        return "ok"
    if partes[0] == "disponible":
        return str(inventario.disponible(partes[1]))
    return "comando desconocido"


if __name__ == "__main__":
    inventario = Inventario()
    for linea in sys.stdin:
        print(ejecutar(inventario, linea.strip()))
EOF

cat > tests/__init__.py <<'EOF'
EOF

cat > tests/test_servicio.py <<'EOF'
import unittest

from inventario.servicio import Inventario


class TestInventario(unittest.TestCase):
    def test_agregar_suma_stock(self):
        inventario = Inventario()
        inventario.agregar("A1", 3)
        inventario.agregar("A1", 2)
        self.assertEqual(inventario.disponible("A1"), 5)

    def test_item_inexistente_tiene_cero(self):
        self.assertEqual(Inventario().disponible("Z9"), 0)


if __name__ == "__main__":
    unittest.main()
EOF

git add . && git commit -qm "init"
git switch -q -c reservas
