# Prototipo

El prototipo es descartable. Su objetivo es tomar una decision de diseno o comportamiento rapido. La implementacion real va despues por Feature. Principio: exhaust-the-design-space.

1. Definir la decision que el prototipo tiene que resolver: que layout, que interaccion, que comportamiento, que enfoque. Si no hay una decision concreta, no hay prototipo: pasar a Feature.
2. Si el espacio de diseno es abierto, juntar referencias y dejar que el usuario elija direcciones antes de construir.
3. Pedirle a Sonnet que construya las variantes en un directorio scratch, fuera del codigo productivo. El brief va en el prompt, sin plan en `Docs/`. El prototipo no se commitea. Para decisiones visuales: HTML/CSS/JS plano o el stack mas liviano, con todas las variantes detras de un selector. Para decisiones de comportamiento: el script mas chico que muestre la diferencia. Sin tests ni abstracciones.
4. Observar el resultado. Script: leer la salida o el timing. Visual: capturar cada variante con Playwright.
5. Presentar variantes, evidencia, tradeoffs y una recomendacion.

**Respuesta:** variantes exploradas, evidencia, tradeoffs, recomendacion y ruta del directorio scratch. Aclarar que el prototipo es descartable.
