---
name: correct
description: Encuentra los errores que los agentes repiten en este repo y propone volverlos imposibles. Prueba primero arquitectura, despues tipos, despues un lint cuyo error nombra el arreglo, despues un test, y deja la documentacion para el final. Usar cuando el usuario escribe /gas-mode:correct.
disable-model-invocation: true
---

# Correct

Adaptado de la skill `correct` del plugin pstack (MIT, ver `LICENSE` en esta carpeta).

El usuario corrige a los agentes de este repo una y otra vez por los mismos errores. El objetivo es cambiar el repo para que el proximo agente no pueda cometerlos.

Suponer que cada contribuidor es un agente que solo ve los archivos que abrio, copia el ejemplo mas cercano y toma el camino mas corto que compila. Disenar el repo para que un cambio que se ve correcto desde un archivo sea correcto para todo el repo.

## 1. Encontrar las clases de error (solo lectura)

Leer:

- Commits recientes y reverts: `git log --oneline -100`, `git log --grep=revert -i`, `git log -p` sobre los archivos mas tocados.
- Comentarios de revision de PRs: `gh pr list --state merged --limit 30` y `gh pr view <n> --comments`.
- El CLAUDE.md del proyecto (resolver su ruta real con `readlink -f CLAUDE.md`) y cualquier `AGENTS.md`.
- Comentarios en el codigo que explican workarounds.

Agrupar los errores en clases. Una clase cuenta si ocurrio al menos dos veces. Para cada una, guardar la evidencia (commit, PR, archivo y linea).

## 2. Elegir el nivel mas alto que funcione

Para cada clase, en este orden:

1. **Eliminarla con arquitectura.** Un solo dueno por pieza de estado y una sola manera soportada por tarea. Ocultar internals para que el import incorrecto falle. Reemplazar listas sincronizadas a mano por una sola fuente de verdad. Borrar las maneras viejas y el codigo muerto que un agente copiaria.
2. **Imponerla con tipos**, para que el estado incorrecto no se pueda escribir. Si el codigo incorrecto igual compila, un lint o un check de CI cuyo mensaje de error nombre el archivo, tipo o funcion que hay que usar. Si el patron ya esta muy extendido, fallar solo cuando un cambio agrega mas casos.
3. **Testear el comportamiento.** Arreglar o borrar tests que siguen pasando cuando el comportamiento se rompe, o que fallan cuando solo cambian los internals.
4. **Documentacion o reglas de agente al final**, solo para decisiones de criterio. Nada falla cuando un agente las ignora.

## 3. Presentar y esperar

Presentar cada clase con su evidencia, el nivel elegido, por que un nivel mas alto no funciona y el cambio propuesto. Esperar la aprobacion del usuario antes de cambiar nada.

Pedir confirmacion explicita para agregar una dependencia nueva (plugin de lint, herramienta de CI) o cambiar la configuracion de CI.

## 4. Implementar lo aprobado

- Implementar con el flujo de `/gas-mode:gas-mode` (`${CLAUDE_PLUGIN_ROOT}/skills/gas-mode/SKILL.md`, seccion "Delegacion a Sonnet"): Opus escribe el plan, Sonnet implementa, Opus verifica y revisa. Una tarea del plan por clase.
- Probar que cada check nuevo falla sobre un error real del pasado: reproducir ese error en un archivo temporal nuevo (no editar archivos existentes para esto), correr el check, ver que falla con el mensaje esperado y borrar el archivo temporal.
- Correr el mismo comando localmente que en CI.
- Las excepciones van en la linea afectada, con motivo, fecha de vencimiento y aprobacion del usuario.
- Commits: segun "Commits" de gas-mode si el modo esta activo; si no, solo cuando el usuario lo pide. Push siempre con confirmacion. Los cambios a la tabla de reglas llegan a la rama por defecto solo via PR.

## 5. Mantener la tabla de reglas

Usar la misma tabla que `/gas-mode:gas-mode` (seccion "Correcciones" de `${CLAUDE_PLUGIN_ROOT}/skills/gas-mode/SKILL.md`): seccion `## Reglas impuestas` del CLAUDE.md del proyecto, con columnas Regla, Lo impone, Nivel y Estado. Editar el archivo real que resolvio `readlink -f`. Si una regla ya estaba en la tabla y nada la impone, es una repeticion: subirla de nivel en el mismo cambio. Borrar una regla cuando su error ya no puede ocurrir.

`/gas-mode:gas-mode` aplica este mismo proceso en el momento, ante cada correccion del usuario. `/gas-mode:correct` es la version que revisa todo el historial: usarla al empezar en un repo o cuando la tabla no refleja errores que se ven en los commits.

**Respuesta:** cada clase con su evidencia, el nivel elegido y por que un nivel mas alto no funciono.
