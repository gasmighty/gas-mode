# Plan y delegacion — flujo compartido

Este archivo lo leen `/junior-plan` (ejecutor `cursor`) y `/sonnet-plan` (ejecutor `sonnet`). Variables que define el comando que lo invoca: `EJECUTOR` y `TAREA`.

Si `TAREA` esta vacia, pedirle al usuario que describa la tarea antes de continuar.

---

## Paso 1 — Leer contexto del proyecto

Leer, si existen y en este orden:
- `CLAUDE.md` / `AGENTS.md` del proyecto actual
- `package.json` (stack, dependencias, scripts disponibles)
- Configuracion relevante (`next.config.ts`, `tsconfig.json`, etc.)

Extraer: stack, convenciones, librerias instaladas, restricciones, patrones del proyecto. Identificar los **archivos directamente relacionados** con la tarea; se usan en el plan.

---

## Paso 2 — Crear el plan en Docs/

1. Crear `Docs/` en la raiz del proyecto si no existe.
2. Nombre en kebab-case con timestamp corto (ej: `Docs/agregar-exportar-csv-20250619.md`).
3. Escribir el plan. El ejecutor no ve esta conversacion, asi que el plan debe ser autosuficiente.

```markdown
# Plan: {nombre descriptivo de la tarea}

**Estado general:** En progreso
**Fecha:** {fecha actual}

## Objetivo

{1-2 oraciones: que se quiere lograr y por que, orientadas a un developer junior}

## Contexto del proyecto

{Stack, convenciones relevantes, patrones existentes que debe seguir}

## Archivos relevantes

- `src/...` — {para que sirve en el contexto de esta tarea}

## Tareas

### Tarea 1 — {nombre}
- [ ] Completada

**Que hacer:**
{instrucciones paso a paso, concretas, sin ambiguedades}

**Warnings:**
{que NO debe hacer, errores comunes, efectos secundarios}

**Como verificar:**
{comando o comportamiento concreto que demuestra que la tarea esta bien hecha (ej: `npm run typecheck` sin errores, la ruta `/x` muestra Y)}

---

{repetir por cada tarea}

## Notas finales

{como testear manualmente, que revisar antes de dar por terminado, casos borde}
```

---

## Paso 2.5 — Confirmar con el usuario

Antes de lanzar nada, mostrar la ruta del plan y un resumen de 2-3 lineas (cantidad de tareas, archivos que se tocaran) y esperar el OK del usuario. Si pide cambios, editar el plan y volver a confirmar.

---

## Paso 3 — Ejecutar

Prompt base para el ejecutor (reemplazar `{plan}` por la ruta absoluta del plan y `{proyecto}` por la del proyecto):

```
Implementa el plan ubicado en {plan}. Directorio de trabajo: {proyecto}.

Instrucciones importantes:
- Lee el plan completo antes de empezar a codear.
- Revisa los archivos de la seccion 'Archivos relevantes' para entender el contexto.
- Implementa las tareas en el orden indicado.
- Cuando termines cada tarea, edita el plan y cambia '- [ ] Completada' por '- [x] Completada'.
- Al finalizar todas, cambia 'Estado general: En progreso' por 'Estado general: Completado'.
- No hagas cambios fuera del alcance del plan.
- Respeta las convenciones del plan y del CLAUDE.md del proyecto.
- No hagas git add, commit, push ni comandos de base de datos que escriban datos.
- Antes de terminar, corre el type-check y el lint del proyecto (si existen) y corrige lo que falle.
- Al terminar, responde con: archivos modificados, salida final del type-check/lint y cualquier desvio del plan.
```

### Si EJECUTOR = cursor

```bash
agent --print --trust --model auto --workspace $(pwd) "{prompt base}"
```

`run_in_background: true`, timeout 300000ms. Avisar al usuario que Cursor esta trabajando.

### Si EJECUTOR = sonnet

Herramienta `Agent` con `subagent_type: general-purpose`, `model: sonnet` (Sonnet 5.5), `run_in_background: true`, `description: "Implementar plan"` y `{prompt base}` como prompt. Avisar al usuario que el subagente esta trabajando. El resultado llega como notificacion; no hacer polling. Guardar el nombre/ID del subagente para el Paso 4b.

---

## Paso 4 — Verificacion objetiva

Cuando el ejecutor termine, correr por cuenta propia (no confiar solo en lo que reporta):

- `npm run typecheck` o `npm run type-check` si existe; si no, `npm run build`
- `npm run lint` si existe

---

## Paso 4b — Lazo de correccion (maximo 2 iteraciones)

Si la verificacion falla o la revision (Paso 5) encuentra errores concretos, devolverselos al ejecutor en vez de corregirlos directamente:

- `sonnet`: `SendMessage` al mismo subagente con los errores exactos (archivo, linea, mensaje). Conserva su contexto.
- `cursor`: nueva ejecucion de `agent --print ...` con un prompt que incluya el plan y los errores a corregir.

Despues de cada iteracion repetir Paso 4. Si tras 2 iteraciones sigue fallando, parar y reportar al usuario el estado y la causa probable; no cambiar de enfoque sin consultar.

---

## Paso 5 — Revision de Claude

Revisar el codigo, no solo el plan:

1. **Leer los archivos modificados** e identificar los cambios.
2. **Correctitud**: implementa lo que pide el plan? Cumple cada "Como verificar"?
3. **Bugs**: variables sin inicializar, casos borde, logica incorrecta, imports faltantes, tipos incorrectos.
4. **Regresiones**: se rompio algo existente?
5. **Convenciones**: sigue los patrones del proyecto?

Si hay errores corregibles, aplicar el Paso 4b antes de reportar. Formato del reporte:

```
## Revision de implementacion

### Estado del plan
{tareas completadas vs pendientes}

### Verificacion automatica
{resultado de type-check / lint / build}

### Archivos modificados
{lista}

### Iteraciones de correccion
{0, 1 o 2, y que se corrigio}

### Resultado
OK / CON OBSERVACIONES / CON ERRORES

### Observaciones
{bugs, regresiones o desvios: archivo, linea aproximada, descripcion}

### Proximos pasos recomendados
{que debe revisar, corregir o testear manualmente el usuario}
```

Si quedan errores criticos (build roto, bugs evidentes), indicar que NO se debe mergear sin corregirlos.

---

## Paso 6 — Preguntar por la limpieza del plan

No borrar el plan automaticamente. Preguntar con `AskUserQuestion` si el plan en `Docs/` se mantiene como historial o se borra, con la recomendacion propia como primera opcion: mantenerlo si hubo observaciones/errores, la tarea fue grande o documenta decisiones utiles; borrarlo si el resultado fue OK y la tarea era chica/rutinaria. Ejecutar solo lo que el usuario confirme.
