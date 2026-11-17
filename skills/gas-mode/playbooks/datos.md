# Datos

Queries, pipelines y transformaciones (BigQuery, dbt, Airflow, scripts de ETL). Cada afirmacion sobre los datos se respalda con un numero medido. Principios: explain-the-number, make-operations-idempotent, boundary-discipline, prove-it-works.

Regla global: ningun comando que escriba datos o esquemas (`CREATE`, `INSERT`, `MERGE`, `UPDATE`, `DELETE`, `bq mk`, `bq load`, `bq cp`, correr un DAG o un `dbt run`). Todo lo que escribe lo ejecuta el usuario.

1. Relevar el contexto (solo lectura): tablas fuente y destino, esquema (`bq show --schema --format=prettyjson <tabla>`), particionado y clustering, volumen (`bq show --format=prettyjson <tabla>`: `numRows`, `numBytes`) y quien consume el destino (refs de dbt, DAGs, dashboards, busqueda en el repo).
2. Definir el contrato del resultado antes de escribir SQL: grano (una fila por que), clave unica, columnas y tipos, reglas de negocio y los checks que lo prueban. Escribirlo en el plan.
3. Escribir el plan (plan-simple) y delegar a Sonnet segun "Delegacion a Sonnet" (SQL, modelos dbt, DAGs, scripts). Los cambios triviales los hace Opus.
4. Antes de ejecutar cualquier query, estimar con `bq query --dry_run --use_legacy_sql=false '<sql>'` y aplicar "Control de costos" de SKILL.md. Filtrar por particion siempre que se pueda. `LIMIT` no reduce los bytes escaneados.
5. Validar sin escribir: correr la transformacion como `SELECT` (sin materializar) sobre una particion o una muestra, y medir:
   - Conteo contra la fuente, con la diferencia explicada (filtros, joins, deduplicacion).
   - Unicidad de la clave: `COUNT(*)` contra `COUNT(DISTINCT clave)`.
   - Nulos en columnas obligatorias, rangos y valores fuera de dominio.
   - Frescura: maximo de la columna de fecha contra lo esperado.
   - En un cambio de logica existente: comparar resultado viejo contra nuevo con `EXCEPT DISTINCT` en ambos sentidos y explicar cada diferencia.

   Si el repo ya tiene queries o tests de validacion para estas tablas (por ejemplo, tests de dbt o un script de checks), usarlos. Si estos checks se escriben a mano por segunda vez para las mismas tablas, proponer guardarlos como tests de dbt o como script en el repo (principio proponer-determinismo).
6. Revisar idempotencia: correr el job dos veces, o retomarlo despues de un corte, tiene que dejar el mismo estado. Preferir `MERGE` por clave o reemplazo de particion antes que `INSERT` que agrega filas; en dbt incremental, `unique_key` definido.
7. Entregar al usuario el comando exacto que escribe (crear tabla, `MERGE`, backfill, correr el DAG), con los bytes estimados. Cuando el usuario confirma que lo corrio, repetir los checks del paso 5 sobre la tabla real, en solo lectura.
8. Commitear segun "Commits" en SKILL.md. Si corresponde subir los cambios, preguntar antes de hacer push.

**Respuesta:** que cambio, el contrato del resultado, cada check con su numero, bytes escaneados por las queries de validacion y el comando que tiene que correr el usuario.
