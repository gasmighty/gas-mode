---
name: create-verification-skill
description: Genera una skill de verificacion local del proyecto (.claude/skills/verify-<app>/) que levanta la app, la maneja como un usuario y captura evidencia, con un mapa de features. Usar cuando el usuario escribe /gas-mode:create-verification-skill, o cuando /gas-mode:gas-mode lo propone porque el proyecto no tiene una forma scripteada de probar comportamiento.
disable-model-invocation: true
---

# Crear una skill de verificacion

Adaptado de la skill `create-verification-skill` del plugin pstack (MIT, ver `LICENSE` en esta carpeta).

Todo proyecto serio necesita una forma scripteada de manejar la app real y probar comportamiento: levantarla, usar una feature como lo haria un usuario y capturar evidencia. Esta skill la genera como una skill local del proyecto en `.claude/skills/verify-<app>/`. El lector de lo que se genera es el proximo agente, no una persona: la va a leer en frio, en medio de una tarea, sin haber visto nunca la app.

## Limites (aplican a todo lo que se genera)

- **Bases de datos:** nunca correr migraciones, seeds ni escrituras de datos. Si un journey necesita datos que no existen, el journey falla y el motivo va en los `Gotchas` de esa feature. Nunca debilitar el journey para que pase.
- **Backend real:** el Doctor tiene que informar contra que backend apunta la instancia (leyendo los nombres de las variables de entorno, nunca imprimiendo secretos). Los journeys que crean, editan o borran datos se marcan como **mutacion** y requieren confirmacion del usuario, salvo que el backend sea un emulador o una base descartable confirmada.
- **Puertos:** usar el servidor de desarrollo en su puerto por defecto. Si ya esta corriendo, reutilizarlo. Si no, levantarlo en ese puerto. Nunca levantar una segunda instancia en otro puerto sin preguntar.
- **Browser:** el paso 4 maneja un browser. Fuera de `/gas-mode:gas-mode`, preguntar antes. Dentro de `/gas-mode:gas-mode`, Playwright esta autorizado.
- **Dependencias:** no instalar nada sin preguntar.
- **Evidencia:** screenshots, snapshots y logs van a un directorio incluido en el `.gitignore` del proyecto. Si no lo esta, agregarlo antes de generar archivos.
- **Sin READMEs en subcarpetas:** el indice del mapa de features se llama `index.md`.

## 1. Entrevistar al repo, no al usuario

Responder desde el codebase y preguntar al usuario solo lo que no se puede observar:

- **Superficie:** que toca realmente el usuario. UI web, CLI/TUI, API, libreria. Si hay varias, elegir la principal y anotar el resto.
- **Ejecucion:** como se levanta la app en local. Preferir el comando documentado del repo (scripts de `package.json`, Makefile, README). Anotar puerto por defecto, nombres de variables de entorno y autenticacion.
- **Manejo:** como puede interactuar un agente:
  - Si el proyecto ya depende de Playwright o Cypress, generar specs scripteados con esa herramienta. Son deterministicos y reutilizables.
  - Si no, usar el MCP de Playwright con handles de rol y nombre accesible (`getByRole`, `getByLabel`).
  - Para CLI: comandos directos con codigo de salida y stdout. Para APIs: `curl`.
- **Observacion:** que evidencia se puede capturar: screenshots, snapshots ARIA, transcripciones de terminal, cuerpos de respuesta, logs, codigos de salida.
- **Backend:** a que apunta la configuracion local (emulador, base local, base compartida o productiva).

Si el checkout no levanta tal cual, reportarlo con precision antes de generar. Una skill escrita sobre una base rota ensena pasos incorrectos.

## 2. Generar la skill

Escribir `.claude/skills/verify-<app>/SKILL.md` con frontmatter YAML (`name: verify-<app>` y una `description` que nombre la app, la superficie y cuando usarla; sin frontmatter la skill no se registra) y estas secciones, todas basadas en lo que encontro la entrevista, sin placeholders:

- **Launch:** el comando exacto que levanta la app en su puerto por defecto, y como saber que esta lista para usarse (una linea de log, una ruta que responde con contenido real). Lista significa usable, no solo que un proceso responde. Incluir como detenerla si la levanto la verificacion.
- **Doctor:** un chequeo de solo lectura que responde "vale la pena manejar esta instancia?": proceso arriba, puerto correcto, build correcto, sesion valida y backend al que apunta. Se corre primero cada vez que algo no cierra.
- **Drive:** la receta con selectores y comandos reales de este repo, no ejemplos. Preferir handles estables (roles ARIA, labels, `data-testid`, rutas) sobre coordenadas u orden de tabulacion.
- **Evidence:** que capturar y donde. Estandar de prueba: recorrer el camino real del usuario, no setters internos ni endpoints de test; capturar la accion y el estado resultante, no solo la pantalla final; verificar efectos secundarios ademas de lo visible; mocks solo donde un limite de produccion ya aisla el sistema externo.
- **Cleanup:** detener solo lo que levanto la verificacion (nunca matar por nombre de proceso). La limpieza no borra la evidencia.
- **Helpers:** cualquier script que incluya la skill es ejecutable y su invocacion aparece en el cuerpo de la skill.

## 3. Sembrar el mapa de features

Crear `.claude/skills/verify-<app>/features/index.md` y un archivo por feature visible para el usuario (empezar por las 3 a 5 principales, sacadas de rutas, comandos, menus o docs). Seguir la forma de `references/feature-map-example/` (el `control-notes` del ejemplo es un harness ficticio; usar el real del proyecto). Cada archivo responde, desde el punto de vista del usuario, que es la feature, como se llega, como manejarla con el harness y que estado final observable prueba que funciona. Los cuatro H2 son `Sub-features`, `How to get to it (user POV)`, `Driving it with <harness>` y `Gotchas`. Marcar los journeys de mutacion.

## 4. Probar la skill generada antes de entregarla

Ejecutar sus propias instrucciones de punta a punta una vez: Launch, Doctor, manejar UNA feature del mapa que no sea de mutacion, capturar evidencia y Cleanup. Despues de Cleanup, confirmar que la evidencia sigue en el lugar indicado. Corregir lo que falle y correr Cleanup despues de cada intento fallido. Una skill generada que nunca se ejecuto es un borrador, no un entregable.

## 5. Entregar

Informar la ruta de la skill, las features mapeadas, que journey se probo y con que evidencia, y que journeys son de mutacion. No commitear salvo segun las reglas de `/gas-mode:gas-mode` o cuando el usuario lo pida.

## Mantenimiento

Cuando `/gas-mode:gas-mode` verifica una feature que el mapa no lista, o encuentra que un journey del mapa ya no coincide con la app, propone agregar o corregir el archivo de esa feature.
