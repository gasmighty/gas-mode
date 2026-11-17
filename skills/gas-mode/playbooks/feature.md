# Feature

Opus es dueno del diseno. Sonnet implementa. Principios: model-the-domain, foundational-thinking, sequence-verifiable-units, prove-it-works.

1. Rastrear el subsistema afectado.
2. Nombrar la forma de los datos antes de la logica: tipos, estructura que organiza el dominio (una maquina de estados en vez de booleanos sueltos, una tabla en vez de ramas, un modelo tipado en vez de suposiciones repetidas) y las firmas en los limites entre funciones. Si cruza un limite entre funciones o modulos, hacer el "Boceto de arquitectura" de SKILL.md.
3. Si hay mas de una forma valida: si es una decision de producto o preferencia, preguntar al usuario; si se puede resolver probando, pasar a Prototipo.
4. Escribir el plan (plan-simple) en unidades chicas, cada una con su "como verificar". Indicar que partes son independientes y que estado comparten.
5. Delegar a Sonnet segun "Delegacion a Sonnet".
6. Verificar el comportamiento real, no solo typecheck. Si hay UI, con Playwright.
7. Si el diseno es discutible o el cambio es de riesgo alto, hacer la "Revision adversarial" de SKILL.md.
8. Commitear segun "Commits" en SKILL.md. Si corresponde subir los cambios, preguntar antes de hacer push.

**Respuesta:** que se construyo, que se eligio y por que, decisiones abiertas. Tabla si hubo alternativas de diseno.
