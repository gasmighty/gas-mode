---
name: gcp-cloud-run-github-deploy
description: >-
  Conecta un repo de GitHub a Cloud Run (GCP) con deploy continuo desde main
  via Cloud Build 2nd gen: APIs, conexion GitHub (OAuth del usuario), Artifact
  Registry, IAM de la SA de compute, trigger, primer build, IAP. Usar al
  deployar por primera vez a Cloud Run, vincular un repo a un servicio, crear
  el trigger de Cloud Build, o cuando fallen builds con INVALID_ARGUMENT,
  Secret Manager, allUsers, o la SA legacy de Cloud Build. Aplica a fronts
  Next.js standalone y a cualquier servicio con Dockerfile en puerto 8080.
---

# GCP Cloud Run + GitHub (primer deploy)

Patron del org (Monks): Cloud Run lee `main` remoto. No hay Vercel. El agente
hace `gcloud`; el usuario hace OAuth de GitHub y confirma IAP en el browser.

**WIP=1.** Completar y verificar un paso antes del siguiente. No borrar SAs ni
bindings ajenos. IAM solo aditivo (`--condition=None`). No commitear ni pushear
salvo que el usuario lo pida.

## Antes de tocar GCP

Leer [references/repo-prerequisites.md](references/repo-prerequisites.md) y
bloquear si falta algo. El build **no** usa el working dir local.

Requisitos minimos:

1. Repo en GitHub, rama `main` pusheada (el commit a deployar tiene que estar
   en origin).
2. `Dockerfile` que escuche **8080** (`PORT` / `EXPOSE`). Next.js: `output:
   "standalone"` y runner `CMD ["node", "server.js"]`.
3. `.dockerignore` (al menos `node_modules`, `.next`, `.git`, `.env*.local`).
4. Node: `package-lock.json` valido para `npm ci`. Correr
   `node scripts/validate-lockfile.js` si existe.
5. Usuario `gcloud` con rol de admin (o equivalente) en el proyecto GCP.
6. Billing activo en el proyecto.

Pedir al usuario si no estan claros: **project id**, **region** (default
`us-central1`), **nombre del servicio**, **emails IAP** (cuentas concretas
que tienen que entrar; nunca un dominio ni un grupo de la org).

## Flujo

Sustituir `PROJECT`, `REGION`, `SERVICE`, `GITHUB_OWNER/REPO`.

### 1. Inspeccion (solo lectura)

```bash
gcloud config get-value account
gcloud projects describe PROJECT --format='value(projectId,projectNumber,lifecycleState)'
gcloud billing projects describe PROJECT --format='yaml(billingAccountName,billingEnabled)'
gcloud run services list --project=PROJECT
gcloud builds triggers list --project=PROJECT --region=REGION
gcloud builds connections list --project=PROJECT --region=REGION
```

Si un API no esta habilitado, `list` falla con `SERVICE_DISABLED`. Anotar
`PROJECT_NUMBER`. Seguir; no asumir que el proyecto esta vacio sin listar.

### 2. APIs

```bash
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  secretmanager.googleapis.com \
  iap.googleapis.com \
  --project=PROJECT
```

### 3. Conexion GitHub (2nd gen)

Si no hay connection `COMPLETE`:

```bash
gcloud projects add-iam-policy-binding PROJECT \
  --member="serviceAccount:service-PROJECT_NUMBER@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
  --role="roles/secretmanager.admin" \
  --condition=None

gcloud builds connections create github github-monks \
  --project=PROJECT --region=REGION
```

El create imprime una URL y queda `PENDING_USER_OAUTH`. **Parar.** El usuario
autoriza GitHub (cuenta con acceso al repo) e instala la GitHub App de Cloud
Build si hace falta. No continuar hasta que avise.

Verificar:

```bash
gcloud builds connections describe github-monks \
  --project=PROJECT --region=REGION --format='value(installationState.stage)'
```

Debe ser `COMPLETE`. Si falla Secret Manager: API apagada o P4SA sin
`secretmanager.admin` (errores `could not assert Secret Manager permissions`).

Luego el repo:

```bash
gcloud builds repositories create SERVICE \
  --remote-uri=https://github.com/GITHUB_OWNER/REPO.git \
  --connection=github-monks --region=REGION --project=PROJECT
```

### 4. Artifact Registry + IAM del trigger

```bash
gcloud artifacts repositories create cloud-run-source-deploy \
  --repository-format=docker --location=REGION --project=PROJECT
```

Si el repo ya existe, seguir.

SA del trigger: **compute default**, nunca la SA legacy
`PROJECT_NUMBER@cloudbuild.gserviceaccount.com`.

```text
projects/PROJECT/serviceAccounts/PROJECT_NUMBER-compute@developer.gserviceaccount.com
```

Roles (reintentar si `concurrent policy changes`):

- `roles/cloudbuild.builds.builder` (casi nunca viene de fabrica)
- `roles/run.admin`
- `roles/artifactregistry.writer`
- `roles/iam.serviceAccountUser`
- `roles/logging.logWriter`

### 5. cloudbuild.yaml + trigger

Copiar [references/cloudbuild.yaml.template](references/cloudbuild.yaml.template)
a `cloudbuild.yaml` en la raiz del repo y reemplazar placeholders.

`options.logging: CLOUD_LOGGING_ONLY` es obligatorio con SA user-managed. Si
falta, el build muere con `INVALID_ARGUMENT` antes de clonar.

Crear el trigger con **inline-config** del archivo local (asi el primer build
no depende de que `cloudbuild.yaml` ya este en GitHub):

```bash
gcloud builds triggers create github \
  --name=SERVICE \
  --repository=projects/PROJECT/locations/REGION/connections/github-monks/repositories/SERVICE \
  --branch-pattern='^main$' \
  --inline-config=cloudbuild.yaml \
  --service-account=projects/PROJECT/serviceAccounts/PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --region=REGION \
  --project=PROJECT
```

Pedir al usuario que commitee `cloudbuild.yaml`. El trigger inline ya deploya
en cada push a `main` aunque el archivo no este en git.

### 6. Primer build

```bash
gcloud builds triggers run SERVICE --branch=main --region=REGION --project=PROJECT
```

Poll `gcloud builds describe BUILD_ID --region=REGION --format='value(status,statusDetail)'`.
Un Next.js Docker suele tardar 3–8 min. Error real: `statusDetail`, no el
resumen de la UI de Cloud Run.

### 7. Acceso HTTP (org policy)

`--allow-unauthenticated` / `allUsers` / `allAuthenticatedUsers` suelen estar
bloqueados (`permitted customer`). No insistir.

Patron: IAP encendido, acceso **solo** a `user:` emails que el usuario liste.
**Nunca** `domain:`, `group:`, `allUsers` ni `allAuthenticatedUsers`. Tampoco
grupos generales de la org (Monks, Media.Monks, `monks.com`, etc.).

```bash
gcloud run services update SERVICE --iap --region=REGION --project=PROJECT
```

Por cada email autorizado:

```bash
gcloud run services add-iam-policy-binding SERVICE \
  --region=REGION --project=PROJECT \
  --member='user:EMAIL' --role=roles/run.invoker

gcloud iap web add-iam-policy-binding \
  --project=PROJECT --region=REGION \
  --resource-type=cloud-run --service=SERVICE \
  --member='user:EMAIL' \
  --role=roles/iap.httpsResourceAccessor
```

Si el usuario no dio emails, pedirlos y no inventar un grupo.

El trigger debe deployar con `--iap` (no `--allow-unauthenticated`) para no
apagar IAP en el proximo push. Actualizar inline-config si el primer yaml no
lo tenia.

`curl` sin identidad da 403; es esperado. El usuario abre la URL con cuenta
`@monks.com`.

## Hard limits

- No usar SA legacy de Cloud Build.
- No borrar SAs, triggers ni bindings de otros servicios del proyecto.
- No cambiar `core/project` global si el usuario trabaja en varios GCP; pasar
  siempre `--project=`.
- No abrir el browser por el usuario; pasarle la URL de OAuth y esperar.
- No agregar a IAP/invoker `domain:`, `group:` de la org, `allUsers` ni
  `allAuthenticatedUsers`. Solo `user:` emails pedidos por el usuario.
- Repo = fuente de verdad del codigo. GCP = fuente de verdad del trigger
  mientras sea inline.

## Pitfalls

Ver [references/pitfalls.md](references/pitfalls.md).
