# Refactor

Cambia la estructura, no el comportamiento. Si aparece un bug o falta una funcionalidad, separarlo y tratarlo despues con su propio playbook. Principios: model-the-domain, subtract-before-you-add, laziness-protocol, migrate-callers-then-delete-legacy-apis, prove-it-works, minimize-reader-load.

1. Fijar el contrato de comportamiento antes de mover nada: un test de caracterizacion, un snapshot o un script que compare salidas. Typecheck y lint no cuentan. Si el area no tiene cobertura, la Tarea 1 del plan es escribir ese test y comprobar que pasa con el codigo actual.
2. Nombrar la estructura que le falta al codigo. Si la forma ya es clara y local, no tocar. El cambio tiene que borrar ramas o estados invalidos, no agregar indireccion.
3. Nombrar la forma objetivo: modulos, tipos y grafo de llamadas como se harian hoy. Si cruza un limite entre funciones o modulos, hacer el "Boceto de arquitectura" de SKILL.md.
4. Restar antes de sumar: borrar codigo muerto, wrappers de un solo uso y validaciones redundantes antes de introducir la forma nueva.
5. Escribir el plan (plan-simple) en pasos chicos que mantienen el test del paso 1 en verde. Para cambios de API, migrar todos los llamadores y borrar la API vieja en la misma ola, sin capas de compatibilidad. Indicar que se revisen los renames en strings, docs y referencias. Delegar a Sonnet segun "Delegacion a Sonnet".
6. Probar que el comportamiento no cambio: correr el test del paso 1 y, si el cambio es grande, comparar salidas viejas contra nuevas.
7. Si el refactor cambia una API usada en muchos lugares, hacer la "Revision adversarial" de SKILL.md. Confirmar que vale la pena: si el diff no reduce la carga de lectura en algun lugar, proponer revertirlo.
8. Commitear segun "Commits" en SKILL.md. Si corresponde subir los cambios, preguntar antes de hacer push.

**Respuesta:** que estructura cambio, contra que contrato se verifico, la prueba de equivalencia y que se mantuvo o se revirtio. Sin comportamiento nuevo.
