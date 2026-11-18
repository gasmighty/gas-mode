# Precondiciones del repo

No crear el trigger si esto no esta listo. Cloud Build clona **origin/main**,
no el working tree.

## Git

- Remote GitHub (ej. `digodat/<repo>`).
- `main` existe en origin y contiene Dockerfile, lockfile y configs.
- `.env` / secretos **no** commiteados (`.gitignore` con `.env*` y
  `!.env.example`).

## Docker / Cloud Run

Archivos en la raiz:

| Archivo | Para que |
|---|---|
| `Dockerfile` | Imagen de produccion |
| `.dockerignore` | Evitar mandar `node_modules`, `.next`, `.git`, `.env*.local` |
| `cloudbuild.yaml` | Ideal en git; el primer trigger puede ir inline |

Contrato Cloud Run:

- Proceso HTTP en **8080**
- Bind `0.0.0.0` (`HOSTNAME=0.0.0.0` en Next standalone)
- Usuario no-root en el runner

### Next.js (App Router)

`next.config`: `output: "standalone"`.

Dockerfile en 3 stages (deps `npm ci` → build → runner). El runner copia:

```
public
.next/standalone  → ./
.next/static      → ./.next/static
```

`CMD ["node", "server.js"]`. `EXPOSE 8080`, `ENV PORT=8080`.

Base image: `node:24-alpine` (o la major que use el `package.json`).

Scripts `build` no deben depender de archivos solo locales (ej. Netskope CA).
En Cloud Build `NODE_EXTRA_CA_CERTS=$HOME/.netskope-ca.pem` **no existe**.
Si el script de build exporta eso, el path ausente suele ser inofensivo; no
poner `NODE_TLS_REJECT_UNAUTHORIZED=0`.

### Node / lockfile

`package-lock.json` tiene que pasar `npm ci` en Linux. Entradas con `dev` /
`optional` y **sin** `version` rompen Cloud Build (`Invalid Version:`) aunque
`npm install` ande en Mac.

Si el repo tiene `scripts/validate-lockfile.js`, ejecutarlo antes de
considerar el repo listo. Si no, al menos un `npm ci` local o equivalente.

## Lo que no hace falta para el primer deploy

- `cloudbuild.yaml` en GitHub (el trigger inline alcanza; igual conviene
  dejarlo en el repo despues).
- APIs de producto (Firestore, GCS, Vertex) salvo que el arranque del
  proceso las requiera.
- IAP en el codigo: se configura en el servicio Cloud Run.

## Checklist rapido

```
- [ ] origin/main tiene el codigo a servir
- [ ] Dockerfile + .dockerignore
- [ ] PORT 8080 / standalone si es Next
- [ ] lockfile apto para npm ci en Linux
- [ ] sin secretos en git
- [ ] usuario admin del proyecto GCP + billing
```
