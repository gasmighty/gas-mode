# Bug fix

Cada linea que se cambia se justifica con evidencia en runtime. Un cambio que "quizas ayude" es una hipotesis, no un fix, y no se entrega. Principios: fix-root-causes, attack-the-premise, prove-it-works, test-behavior-not-implementation.

1. Reproducir (Opus). Usar comandos, tests, curl o un script chico. Si es un bug de UI, reproducirlo con Playwright sin preguntar (ver "Browser" en SKILL.md) y guardar la evidencia (screenshot, consola o asercion). Si no reproduce, sintetizar el disparador, ajustar condiciones o agregar instrumentacion temporal hasta que aparezca.
2. Buscar la causa por descarte. Listar hipotesis, conseguir evidencia en runtime y eliminar hasta que quede una. Revisar la historia con `git log` y `git blame` si es una regresion. No adivinar: si el estado no es claro, instrumentar y leerlo mientras corre.
3. Confirmar el mecanismo con evidencia antes de planear el fix.
4. Preguntar si el estado que disparo el sintoma es legitimo. Si lo es, manejarlo donde se rompio. Si no deberia existir, buscar que lo produce. Guards, retries, errores tragados, valores clampeados o estado descartado no son fixes para un estado ilegitimo.
5. Buscar otras instancias del mismo patron y sumarlas al alcance.
6. Si dos fixes con la misma premisa fallaron, aplicar attack-the-premise antes de un tercero.
7. Si el fix cruza un limite entre funciones o modulos, hacer el "Boceto de arquitectura" de SKILL.md. Escribir el plan (plan-simple). Incluir el repro, la causa raiz y su evidencia. Si hay un camino de test barato, la Tarea 1 es un test que falla antes del fix. Delegar a Sonnet segun "Delegacion a Sonnet".
8. Verificar en el mismo lugar donde se reprodujo (Playwright si fue un bug de UI): el repro original ahora pasa. Quitar la instrumentacion temporal. Correr los tests.
9. Commitear segun "Commits" en SKILL.md. Si corresponde subir los cambios, preguntar antes de hacer push.

**Respuesta:** que estaba roto, causa raiz, fix y como se verifico. Pegar la salida del repro antes y despues.
