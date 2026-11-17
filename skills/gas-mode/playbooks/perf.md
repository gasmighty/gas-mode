# Perf

Cada mejora se ata a una medicion. No reemplazar la medicion por leer codigo. Principios: explain-the-number, sequence-verifiable-units, prove-it-works.

1. Medir la linea base (Opus): benchmark, timing o profiler. Validar el numero con explain-the-number: repeticiones, dispersion, que lo limita, que mide realmente.
2. Formar hipotesis a partir de la medicion. Probar las ideas en este orden, de la mas barata a la mas cara, y frenar cuando una alcanza el objetivo:
   1. No hacerlo (cortar trabajo cuyo resultado no se usa).
   2. Hacerlo una sola vez.
   3. Hacerlo menos.
   4. Hacerlo despues.
   5. Hacerlo cuando nadie mira.
   6. Hacerlo en paralelo.
   7. Hacerlo mas barato.
3. Escribir el plan (plan-simple) con una mejora por tarea y la medicion como "como verificar" de cada una. Delegar a Sonnet segun "Delegacion a Sonnet".
4. Medir despues de cada tarea con el mismo metodo que la linea base y comparar. Un resultado no concluyente no cuenta como mejora.
5. Commitear segun "Commits" en SKILL.md. Si corresponde subir los cambios, preguntar antes de hacer push.

**Respuesta:** numero base, numero despues, delta, como se midio y donde estan los resultados.
