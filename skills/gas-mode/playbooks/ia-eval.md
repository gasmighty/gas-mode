# IA / Eval

Cambios en prompts, modelos, parametros, retrieval, tools o agentes. "Ahora responde mejor" no cuenta sin una medicion sobre un set fijo. Principios: explain-the-number, prove-it-works, sequence-verifiable-units.

1. Encuadrar: que variante se prueba (prompt, modelo, temperatura, retrieval, tool), que cuenta como exito y las metricas: una rubrica de calidad de 3 a 6 criterios concretos, costo por llamada y latencia (p50 y p95). Si hay un objetivo, acordar una regla de corte antes de empezar: objetivo mas un minimo de iteraciones o un presupuesto.
2. Set de casos: reutilizar el que ya tenga el repo. Si no hay, armar 15 a 30 casos representativos con datos reales, incluyendo bordes y fallas conocidas. Si los casos contienen datos de clientes, guardarlos en un directorio incluido en el `.gitignore`. Si no hay salidas esperadas, mostrarle al usuario el set y la rubrica antes de correr.
3. Harness: un script que corre una variante sobre el set y guarda por caso la salida, tokens de entrada y salida, latencia y errores en JSONL. Parametros fijos (temperatura, seed si el proveedor lo permite). Se escribe con plan y Sonnet segun "Delegacion a Sonnet". Una vez validado, no se cambia durante la comparacion. Si el repo ya tiene un harness o un set de casos, reutilizarlo. Si se arma una corrida ad hoc por segunda vez para el mismo flujo, proponer dejar el harness y el set en el repo con un comando unico para correrlos (principio proponer-determinismo).
4. Estimar el costo de cada corrida (casos x tokens x precio del modelo) y aplicar "Control de costos" de SKILL.md. Consultar precios vigentes con la skill `claude-api` o la documentacion del proveedor; no de memoria.
5. Correr la linea base y la variante. Evaluar con:
   - Checks deterministicos primero: formato, schema JSON, campos obligatorios, longitud.
   - Un juez LLM para la rubrica, de una familia distinta al generador cuando se pueda. Ve las salidas con etiquetas anonimas (A y B, orden aleatorio por caso), nunca el nombre del modelo ni de la variante. Puntua ambas variantes en una sola pasada, con la misma escala.
6. Leer personalmente una muestra de salidas (al menos 5, incluidas las peores) y comparar con el veredicto del juez. Si no coinciden, la rubrica es ambigua o el juez esta sesgado: corregir la rubrica y re-evaluar.
7. Iterar si hay objetivo: una hipotesis por vuelta, cada variante en su propio archivo (por ejemplo `prompts/v3.md`) para no tener que revertir. Registrar cada vuelta en un `decisiones.tsv` dentro de un directorio incluido en el `.gitignore`: hipotesis, cambio, antes, despues, delta, veredicto. Frenar al cumplir la regla de corte; no relajarla para cumplirla.
8. Promover la variante ganadora y commitear segun "Commits" en SKILL.md. Si corresponde subir los cambios, preguntar antes de hacer push.

**Respuesta:** variante probada, rubrica, cantidad de casos, linea base contra final por criterio, delta de costo y latencia, ejemplos de fallas que quedan y una recomendacion sobre promover o no la variante.
