---
name: github-actions-cost
description: Mide cuanto tiempo y cuantos minutos facturados consume el CI de GitHub Actions de un repo y propone cambios para bajarlos, con medicion antes y despues. Usar cuando el usuario pregunta por que el CI es lento o caro, cuantos minutos gasta, o pide optimizar workflows de GitHub Actions.
---

# Costo y velocidad de GitHub Actions

Cada propuesta sale de una medicion y se vuelve a medir despues de aplicarla. Solo lectura hasta que el usuario elige que cambiar.

## 1. Medir

```bash
node ${CLAUDE_SKILL_DIR}/scripts/measure.mjs OWNER/REPO --days 14 --out <scratch>/ci.json
```

Requiere `gh` autenticado con acceso de lectura al repo y Node 18 o superior. Opciones: `--days` (periodo, default 14), `--max-runs` (tope de corridas, default 500), `--out` (JSON completo).

El script devuelve, en total, por workflow y por job:

| Campo | Que es |
|---|---|
| `minutes` | Duracion real sumada de los jobs. |
| `billedMinutes` | Cada job redondeado al minuto siguiente y multiplicado por el multiplicador del sistema operativo (linux 1, windows 2, macos 10, self-hosted 0). |
| `roundingWasteMinutes` | Minutos facturados que no se usaron por el redondeo. Alto cuando hay muchos jobs cortos. |
| `cancelledMinutes` | Minutos facturados de jobs cancelados. |
| `p50Minutes`, `p90Minutes` | Duracion tipica y de cola de cada job. |
| `runsPerPr` | Corridas promedio por PR. Alto cuando cada push dispara todo el CI. |

En un repo publico los runners estandar no se facturan: leer los minutos como tiempo de espera, no como costo. Si el script avisa que llego a `--max-runs`, los totales no cubren todo el periodo; subir el tope o acortar `--days`.

## 2. Entender que protege cada job

Antes de proponer, leer los workflows y anotar:

- Triggers, `concurrency`, path filters y grafo de `needs:`.
- Checks requeridos: `gh api repos/OWNER/REPO/rulesets` y `gh api repos/OWNER/REPO/branches/<rama>/protection`. Renombrar o sacar un check requerido bloquea todos los merges.
- Que consume el deploy (imagenes, artefactos, estado "CI passed").

## 3. Proponer

Una tabla con: cambio, minutos facturados ahorrados (estimados a partir de la medicion), tiempo de espera ahorrado y riesgo. Patrones frecuentes:

| Patron | Que ataca | Efecto en minutos y espera |
|---|---|---|
| `concurrency` con `cancel-in-progress: true` en PRs | Corridas viejas que siguen corriendo despues de un push nuevo | Baja minutos; puede subir `cancelledMinutes` de corta duracion |
| Path filters (`paths`, `paths-ignore`) | Jobs que corren aunque el cambio no los afecta | Baja minutos y espera |
| Cache de dependencias (`actions/setup-*` con `cache:` o `actions/cache`) | Instalacion repetida en cada job | Baja minutos y espera |
| `timeout-minutes` por job | Jobs colgados que corren hasta el limite de 6 horas | Acota el peor caso |
| Unir jobs cortos | `roundingWasteMinutes` alto | Baja minutos; sube la espera |
| Paralelizar con matrix o jobs separados | Jobs largos en serie | Baja la espera; sube minutos |
| Mover jobs de macOS o Windows a Linux | Multiplicador 10 o 2 | Baja mucho los minutos; solo si el job no necesita ese SO |

Decir para que lado mueve cada cambio. Esperar a que el usuario elija.

## 4. Aplicar y volver a medir

- Un cambio por commit, con un comentario en el YAML que explique el motivo de cada cambio no obvio (restriccion que el YAML no puede expresar).
- Validar con `actionlint` si esta instalado; si no, preguntar antes de instalarlo.
- El primer run de un workflow modificado suele correr todo: avisarlo antes del push.
- Despues de suficientes corridas, volver a correr el script con el mismo `--days` y comparar contra el paso 1. Una mejora sin medicion posterior se reporta como estimada.

**Respuesta:** minutos y tiempos antes, cambios aplicados con su ahorro estimado y, si ya hay datos, el ahorro medido.
