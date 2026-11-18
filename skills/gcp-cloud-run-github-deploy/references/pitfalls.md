# Pitfalls — Cloud Run + Cloud Build

## SA del trigger

No usar `PROJECT_NUMBER@cloudbuild.gserviceaccount.com`. En proyectos nuevos
Google no la crea; `build.service_account` responde `INVALID_ARGUMENT`.

Usar `PROJECT_NUMBER-compute@developer.gserviceaccount.com`. Falta habitual:
`roles/cloudbuild.builds.builder`.

Con SA user-managed, `options.logging` tiene que ser `CLOUD_LOGGING_ONLY` (o
un `logs_bucket`). Si no, el mismo `INVALID_ARGUMENT` antes de clonar.

## Secret Manager en la connection GitHub

`connections create github` guarda el OAuth token en Secret Manager.
Hace falta la API y que
`service-PROJECT_NUMBER@gcp-sa-cloudbuild.iam.gserviceaccount.com` tenga
`roles/secretmanager.admin`. Sin eso: `could not assert Secret Manager
permissions`.

## IAM concurrente

Varios `add-iam-policy-binding` en paralelo pueden fallar con
`subject of a conflict`. Serializar y reintentar el rol que falto.

## Org policy de identidad

`allUsers` / `allAuthenticatedUsers` / `--allow-unauthenticated` fallan con
`permitted customer`. Usar IAP y bindings `user:EMAIL` que el usuario
indique, en **invoker** e **iap.httpsResourceAccessor**.

**Nunca** agregar a IAP (ni a invoker) grupos generales de la org:
`domain:monks.com`, `group:` de Media.Monks/Monks, `allUsers`,
`allAuthenticatedUsers`. Un dominio entero deja el servicio abierto a
cualquier cuenta corporativa.

Un `curl` anonimo a `*.run.app` da 403 con IAP; no es un build roto.

`gcloud run deploy` sin `--iap` puede dejar IAP apagado. El yaml del trigger
tiene que incluir `--iap`.

## Diagnostico de builds

```bash
gcloud builds describe BUILD_ID --region=REGION --project=PROJECT \
  --format='value(status,statusDetail)'
```

La UI de Cloud Run resume mal muchos fallos como `INVALID_ARGUMENT`.

## Codigo vs trigger

El build usa el commit de GitHub, no archivos locales sin pushear.
El trigger **inline** usa el yaml guardado en GCP, no el `cloudbuild.yaml`
del repo, hasta que se cambie a `--build-config`.

## Proyectos compartidos

Antes de IAM/triggers: `describe` / `list` / `get-iam-policy`. Nunca borrar
SAs ni bindings de otras tools.
