# Deploy GCP

Deployar, diagnosticar un build roto o investigar un problema de un servicio en Cloud Run o Cloud Build. Primero se entiende el estado en solo lectura; despues se cambia lo minimo. Principios: fix-root-causes, prove-it-works, make-operations-idempotent.

Antes de empezar, si el CLAUDE.md global o el del proyecto tienen una seccion sobre GCP o deploy, leerla. Para conectar un repo a Cloud Run por primera vez, seguir `<raiz del plugin>/skills/gcp-cloud-run-github-deploy/SKILL.md` (leerla por ruta; `<raiz del plugin>` esta definida en SKILL.md).

1. Identificar el objetivo (solo lectura): proyecto, region, servicio y trigger. `gcloud config list`, `gcloud run services describe <servicio> --region <region>`, `gcloud builds triggers list --region <region>`. Si hay mas de un proyecto o servicio posible, preguntar cual.
2. Diagnosticar (solo lectura): ultimo build y su error real (`gcloud builds list --limit 5`, `gcloud builds describe <id> --format="value(statusDetail)"`), revisiones y trafico (`gcloud run revisions list --service <servicio> --region <region>`) y logs (`gcloud logging read` con filtro por servicio y severidad, acotado en tiempo).
3. Buscar la causa por descarte. Confirmar que lo que construye Cloud Build esta commiteado y pusheado: el build lee la rama remota, no el working dir local.
4. Corregir en el lugar que corresponde:
   - Codigo, `Dockerfile` o `cloudbuild.yaml`: plan y Sonnet segun "Delegacion a Sonnet".
   - Infra (IAM, trigger, configuracion del servicio, secretos): proponer el comando exacto, explicar que cambia y esperar confirmacion. IAM solo aditivo (`add-iam-policy-binding ... --condition=None`); nunca borrar service accounts ni bindings ajenos.
5. Deployar con confirmacion: por push a la rama del trigger (ver "Commits" y la regla de push) o con `gcloud run deploy`. Antes de confirmar, decir que dispara el deploy y a que entorno llega.
6. Verificar en el servicio real:
   - El build termina en `SUCCESS`.
   - La revision nueva recibe el trafico esperado.
   - El endpoint de salud o una ruta real responde con contenido correcto (`curl`; si el servicio esta detras de IAP o requiere auth, con un token de identidad).
   - Los logs de los primeros minutos despues del deploy no muestran errores nuevos.

Si el deploy hoy es manual o depende de pasos a mano que fallan, proponer al final automatizarlo (trigger de Cloud Build o workflow de GitHub Actions con OIDC, sin keys de larga duracion). No construirlo sin confirmacion; si se acepta, seguir `playbooks/ci-cd.md`.

**Respuesta:** que estaba pasando, causa raiz con la evidencia (error del build, logs), que se cambio (codigo o comando de infra), como se deployo y la verificacion del servicio real.
