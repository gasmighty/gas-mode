---
name: interrogate
description: Revision adversarial de un cambio o diseno. Varios subagentes intentan romperlo y solo sobreviven los hallazgos que una ejecucion demuestra. Reporta, no corrige. Usar cuando el usuario escribe /gas-mode:interrogate.
disable-model-invocation: true
---

# Interrogate

Adaptado de la skill `interrogate` del plugin pstack (MIT, ver `LICENSE` en esta carpeta).

Varios adversarios intentan romper un cambio o un diseno. Un hallazgo sobrevive solo si una ejecucion lo demuestra. Se reportan los hallazgos; no se aplican fixes.

**Modelos de los adversarios:** `opus`, `sonnet`. Agregar `fable` solo si el usuario lo pide para esta revision.

## 1. Encuadre

- **Alcance:** lo que nombre el usuario. Si no nombra nada, el diff de la rama contra su base (`git merge-base HEAD main`, o la rama base que corresponda) mas los cambios sin commitear.
- **Intencion:** reformular en dos o tres oraciones que tiene que lograr el cambio, a partir del pedido del usuario, los commits y el plan en la carpeta de documentacion del proyecto (`docs/` o `Docs/`) si existe. Si la intencion no es clara, preguntar.
- `<scratch>` es el directorio scratch de la sesion si existe; si no, uno creado con `mktemp -d`. Siempre fuera del repo.
- Guardar el estado del arbol: `git status --porcelain > <scratch>/interrogate-before.txt`.

## 2. Lanzar los adversarios

Lanzar un subagente por modelo, en paralelo, con la herramienta `Agent` (`subagent_type: general-purpose`, `model: <modelo>`, `run_in_background: true`). Cada uno recibe el alcance, la intencion y este brief, con `<dir>` reemplazado por un directorio scratch propio fuera del repo (por ejemplo, `<scratch>/interrogate/<modelo>/`):

> Intenta romper este cambio. Demostra cada hallazgo con una ejecucion contra el codigo real: un test que falla, un script de repro o la salida de un comando que muestra el comportamiento incorrecto. Para un diseno o un plan, ejecuta un prototipo o sondea el arbol actual.
>
> Reglas:
> - No modifiques ningun archivo del repo. Tus scripts, tests y archivos van en `<dir>`. Si un test solo corre dentro del arbol, crea un archivo nuevo con un nombre unico, correlo y borralo antes de terminar.
> - No escribas en bases de datos, no llames APIs pagas en loop, no hagas commits, push ni cambios de rama.
> - Reporta cada hallazgo con: titulo, comando exacto, salida que imprimio y salida que requiere la intencion.
> - Deja afuera todo lo que no ejecutaste: estilo, nombres, estructura y riesgos que necesitan un cambio futuro para importar.
> - "Sin hallazgos" es un resultado valido.

## 3. Verificar

Cuando terminan todos:

1. Comparar `git status --porcelain` contra `interrogate-before.txt`. Si hay diferencias, reportarlas como falla de la revision y pedirle al usuario que decida que hacer con esos archivos. No limpiar con `git restore`, `checkout --`, `clean` ni `stash`.
2. Re-ejecutar el comando de cada hallazgo. Mantenerlo solo si la salida muestra la falla y la falla rompe la intencion. Descartar el resto.
3. Unir los hallazgos que comparten causa raiz.

## 4. Reporte

- **Intencion:** la reformulacion.
- **Hallazgos:** para cada hallazgo verificado, el comando, su salida, como rompe la intencion y que adversarios lo encontraron. Si no sobrevive ninguno, decir "sin hallazgos verificados".
- **Descartados:** por adversario, cuantos hallazgos se descartaron y por que.

Dentro de `/gas-mode:gas-mode`, los hallazgos verificados vuelven a Sonnet con `SendMessage` como errores concretos. Cuentan como una iteracion mas del lazo de correccion de gas-mode (maximo 2 en total).
