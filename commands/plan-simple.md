# Plan Simple — Escribir un buen plan de implementacion

La tarea a planificar es: **$ARGUMENTS**

Si `$ARGUMENTS` esta vacio, pedirle al usuario que describa la tarea antes de continuar.

Este comando SOLO escribe el plan. No delega a Cursor Agent ni a ningun otro
subagente, no ejecuta codigo y no hace verificacion posterior — para eso existen
`junior-plan` (delegacion headless) y `junior-orca` (delegacion en pestana de Orca).

**Lector del plan:** un developer de bajo seniority que nunca trabajo en este proyecto,
o un agente sin acceso a esta conversacion. No conoce el dominio, la historia del
proyecto, los accesos que hacen falta ni los riesgos. El plan tiene que poder ejecutarse
sin adivinar nada y sin preguntar lo que ya se sabia al escribirlo.

---

## Paso 1 — Leer contexto del proyecto

Leer los siguientes archivos si existen (en este orden de prioridad):
- `CLAUDE.md` del proyecto actual
- `README.md`
- `package.json` (o equivalente) para identificar stack, dependencias y scripts disponibles
- Cualquier archivo de configuracion relevante (`next.config.ts`, `tsconfig.json`, `Dockerfile`, `cloudbuild.yaml`, CI, etc.)

Extraer: stack tecnologico, convenciones de codigo, librerias instaladas, restricciones, patrones del proyecto.

Identificar tambien los **archivos directamente relacionados** con la tarea (componentes, rutas, modulos, tipos) — se usaran en el plan.

---

## Paso 2 — Relevar lo que el lector no sabe

Antes de definir tareas, juntar la informacion operativa que alguien nuevo necesita.
Cada punto se verifica leyendo archivos o corriendo comandos de solo lectura, no se supone.

1. **Linea base:** correr typecheck, lint y tests (los que existan en los scripts) y anotar si hoy pasan. Si un comando no se puede correr (por ejemplo, el build mientras corre el dev server), dejarlo como primer paso del plan.
2. **Como se levanta el proyecto:** comandos de setup, version de runtime, puerto, variables de entorno necesarias (nombres, nunca valores secretos), registries privados o tokens que pide la instalacion.
3. **Accesos necesarios:** credenciales de cloud, roles/permisos, repos privados, servicios externos. Para cada uno: como se consigue y que falla si falta.
4. **Como se despliega:** que dispara un deploy (por ejemplo, un trigger en push a `main`). Si un push puede llegar a produccion, el plan lo tiene que advertir.
5. **Datos y costos:** si en local se trabaja contra bases o servicios productivos, y que operaciones cuestan dinero (APIs pagas, generacion con modelos, cloud).
6. **Supuestos sin verificar:** lo que el plan da por cierto pero no se pudo comprobar. Se listan explicitamente en el plan.

---

## Paso 3 — Mapear los archivos antes de definir tareas

Antes de escribir las tareas, decidir que archivos se van a crear y cuales se van a
modificar, y que responsabilidad tiene cada uno. Esto es lo que despues define donde
corta cada tarea — si dos cambios tocan el mismo archivo por la misma razon, probablemente
sean la misma tarea; si un archivo mezcla responsabilidades muy distintas, probablemente
sean tareas separadas.

- Preferir archivos chicos con una responsabilidad clara sobre archivos grandes que hacen de todo.
- Seguir los patrones que ya existen en el proyecto — si el codebase usa archivos grandes, no reestructurar por iniciativa propia.
- Cada tarea del plan final debe dejar el codigo en un estado testeable, no a mitad de camino.
- Si se mueve codigo (archivos, providers, contextos, rutas), revisar quien lo consume antes de decidir donde queda. Un provider que se mueve fuera del alcance de un consumidor puede fallar en silencio.
- Si la tarea es grande (varios modulos o mas de ~8 tareas), agruparla en **etapas**. Cada etapa tiene su objetivo, sus archivos relevantes y sus tareas con la estructura del Paso 4.

---

## Paso 4 — Crear el plan en Docs/

1. Crear la carpeta `Docs/` en la raiz del proyecto si no existe.
2. Generar un nombre de archivo en kebab-case basado en la tarea, con un timestamp corto para evitar colisiones (ej: `Docs/agregar-exportar-csv-20250619.md`).
3. Escribir el plan con la siguiente estructura. Las secciones de "Antes de empezar" que no apliquen se omiten (por ejemplo, sin accesos especiales no hace falta la tabla), pero se evalua cada una.

```markdown
# Plan: {nombre descriptivo de la tarea}

**Estado general:** En progreso
**Fecha:** {fecha actual}

## Objetivo

{Que se quiere lograr y por que. Incluir el problema actual que motiva el cambio, explicado para alguien que no conoce el proyecto}

## Decisiones tomadas

{Decisiones ya acordadas con el usuario y su motivo, para que el lector no las reabra. Omitir si no hay}

## Que esta verificado y que no

{Lo que se comprobo al escribir el plan (y como), y los supuestos pendientes con la tarea que los confirma}

## Contexto del proyecto

{Stack, convenciones relevantes, patrones que ya existen en el codebase que debe seguir}

## Antes de empezar

### Glosario
{Terminos del dominio y del proyecto que aparecen en el plan, en una linea cada uno}

### Accesos necesarios
{Tabla: acceso, como se consigue, para que sirve / que falla sin el}

### Preparar el entorno
{Comandos copiables: version de runtime, clonar repos, instalar, `.env.local` de plantilla sin secretos, como levantar y en que puerto}

### Linea base
{Resultado actual de typecheck, lint, tests y build. Aclarar que cualquier error nuevo lo introduce el trabajo del plan}

### Flujo de trabajo
{Rama de trabajo, un commit por tarea, que no se debe pushear y por que, como marcar avance en este archivo, quien revisa}

### Prueba de humo
{Pasos manuales cortos que confirman que lo que ya funcionaba sigue funcionando, sin efectos caros ni irreversibles. Se corre al cerrar cada etapa o tarea grande}

### Riesgos que aplican a todo el plan
{Datos productivos, costos, secretos, deploy accidental, y la regla: si algo no coincide con el plan, frenar y consultar}

### A quien consultar
{Personas o roles por tema: dueno del plan, dueno de otro repo o servicio, administradores de cloud}

## Archivos relevantes

{Lista de archivos que se van a crear o modificar, con la responsabilidad de cada uno segun el Paso 3. Incluir rutas relativas desde la raiz del proyecto}

- `src/...` — {que hace / que va a hacer, en el contexto de esta tarea}
- `src/...` — {idem}

## Tareas

### Tarea 1 — {nombre}
- [ ] Completada

**Que hacer:**
{instrucciones paso a paso, concretas, sin ambiguedades. Si hay codigo o firmas de funciones involucradas, escribirlas explicitamente — no describir "que" hacer sin mostrar "como". Comandos listos para copiar. Terminar con como verificar la tarea}

**Depende de / Deja disponible:**
{si esta tarea usa algo de una tarea anterior (una funcion, un tipo, un endpoint), nombrarlo exacto. Si otra tarea va a usar algo de esta, nombrar exacto lo que va a estar disponible y con que firma}

**Warnings:**
{cosas que NO debe hacer, errores comunes, efectos secundarios a tener en cuenta. Ver el checklist del Paso 5}

---

{repetir por cada tarea; si hay etapas, agrupar las tareas bajo "## Etapa N — {nombre}" con su Objetivo y Archivos relevantes}

## Notas finales

{orden obligatorio de tareas o etapas, verificacion al cerrar cada tarea, como revertir, que queda fuera del alcance}
```

---

## Paso 5 — Autorevision antes de entregar el plan

Antes de mostrarle el plan al usuario, releerlo como lo leeria alguien sin contexto y revisarlo contra la tarea pedida:

1. **Cobertura:** cada parte de lo que pidio el usuario tiene una tarea que la cubre? Si falta algo, agregar la tarea.
2. **Sin placeholders ni vaguedades:** buscar y corregir frases como "agregar validacion", "manejar casos borde", "similar a la Tarea 1" (sin repetir el detalle), "corregir lo que rompa" (sin decir donde mirar), "TODO", "completar despues". Cada paso tiene que tener el contenido real.
3. **Tamano y orden de las tareas:** cada tarea deja algo testeable de forma independiente? Lo que una tarea necesita (imports, tipos, configuracion) ya existe al llegar a ella, o se crea en una tarea posterior? Si una tarea es en realidad dos cosas sin relacion, separarla. Si dos tareas son en el fondo un solo cambio, unirlas.
4. **Consistencia de nombres:** los nombres de funciones, componentes, tipos o rutas que aparecen en "Depende de / Deja disponible" de una tarea coinciden exactamente con como se nombran en la tarea donde se definen? Un nombre que cambia entre tareas es un bug del plan.
5. **Lectura sin contexto:** cada termino del dominio esta en el glosario? Cada comando se puede copiar y correr tal cual? Cada referencia a un numero de linea aclara que puede haberse corrido y cita el texto a buscar? Las acciones que no puede hacer el lector (dar permisos, deployar, decidir negocio) dicen quien las hace?
6. **Afirmaciones verificadas:** cada warning o instruccion que describe como se comporta el codigo actual se comprobo leyendo ese codigo? Un warning sobre un comportamiento que no existe confunde mas de lo que ayuda: verificarlo o quitarlo.
7. **Checklist de warnings:** para cada tarea, evaluar si aplica alguno de estos riesgos y, si aplica, escribir el warning concreto (que pasa y como evitarlo):
   - Escritura o borrado sobre datos reales o productivos.
   - Operaciones que cuestan dinero (APIs pagas, modelos, cloud).
   - Deploy accidental (push a una rama con trigger, merge, publicacion).
   - Secretos: tokens, keys o `.env` que podrian terminar en un commit, el plan o un log.
   - Acciones irreversibles o hacia afuera (borrar recursos, enviar mensajes, apagar servicios). Requieren confirmacion explicita.
   - Fallas silenciosas: cambios que no tiran error pero rompen comportamiento (contextos con valor por defecto, imports que resuelven a otro archivo, configuracion que solo se lee en produccion).
   - Diferencias entre local y produccion (credenciales propias vs service account, `next dev` vs build standalone, variables solo de build).
   - Choques: archivos, rutas, nombres o variables de entorno que ya existen y se podrian pisar.
   - Regresiones: funcionalidad existente que la tarea puede romper y como comprobar que sigue funcionando.

Corregir lo que encuentre directamente en el archivo, sin necesidad de volver a repetir toda la revision despues de corregir.

---

## Paso 6 — Presentar el plan

Mostrarle al usuario un resumen breve (objetivo + lista de etapas o tareas), que se verifico
y que quedo como supuesto pendiente, y la ruta del archivo en `Docs/`. La ejecucion del plan
queda en manos del usuario o de lo que decida usar para implementarlo — este comando no la inicia.
