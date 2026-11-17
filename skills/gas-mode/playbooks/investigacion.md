# Investigacion

Solo lectura. El resultado es una explicacion con citas a archivos o una recomendacion, no un cambio de codigo. Sin Sonnet, sin plan, sin ediciones.

1. Rastrear el codigo de la pregunta. Para busquedas amplias, usar un subagente Explore.
2. Si la pregunta es "por que esta asi", leer la historia: `git log -S`, `git log -L`, `git blame` y los PRs relacionados con `gh pr view` (solo lectura). Citar lo que escribieron los autores y marcar lo que es inferencia propia.
3. Producir: Panorama / Conceptos clave / Como funciona / Donde vive / Trampas. Si la pregunta es una decision entre alternativas, dar una recomendacion con tabla de tradeoffs.
4. Si la investigacion termina en un cambio de codigo, proponer pasar a Bug fix o Feature y esperar confirmacion.

**Respuesta:** el resultado de la investigacion. Para preguntas del tipo "estamos seguros?", el juicio real con sus razones. Si la premisa de la pregunta es incorrecta, decirlo.
