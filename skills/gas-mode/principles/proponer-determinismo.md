# Proponer determinismo

Principio propio. Combina `build-the-lever` y `encode-lessons-in-structure` de pstack con la regla del usuario: proponer, no implementar.

**Por que:** cada vez que un problema ya resuelto se vuelve a resolver razonando, se gastan tokens y tiempo sin agregar nada nuevo, y el resultado puede variar. El razonamiento sirve para descubrir soluciones nuevas, no para redescubrir una conocida.

**Cuando aplica:** la segunda o tercera vez que aparece, en esta tarea o en tareas anteriores visibles en el contexto:

- La misma secuencia de comandos.
- El mismo debugging manual o el mismo analisis.
- La misma busqueda en el codigo.
- Las mismas queries de validacion o la misma corrida de evaluacion.
- La misma instruccion escrita por segunda vez en un plan, un brief o una respuesta.

**Que hacer:**

1. Decirlo apenas se detecta, no en silencio ni solo al final.
2. Proponer la forma mas simple que lo vuelve deterministico:
   - Script o CLI para tareas mecanicas.
   - Hook o comando de Claude Code para pasos que siempre siguen la misma secuencia.
   - Skill o workflow cuando el patron es mas complejo pero predecible.
   - Lint, check o test cuando lo que se repite es una correccion (ver `/correct`).
3. La propuesta dice que automatizaria, donde viviria (ruta concreta), como se invoca y que repeticion elimina.
4. No construirlo sin confirmacion del usuario.

**Cuando no aplica:** exploracion genuina, casos con incertidumbre real o tareas que cambian de forma cada vez. Esos se siguen resolviendo razonando.
