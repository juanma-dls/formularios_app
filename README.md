# Formularios

Plataforma para crear formularios públicos (inscripciones, encuestas, votaciones) cuyas respuestas se guardan automáticamente en Google Sheets. Pensada para organismos públicos y organizaciones que necesitan datos validados, como DNI, y control de un voto por persona.

## Qué hace

- Organiza el trabajo en **organizaciones**, **áreas** y **formularios**, para ofrecerse como servicio a varias organizaciones.
- Constructor de formularios con 11 tipos de pregunta (incluidos DNI y opción única con imagen), edición en el lugar, reordenamiento arrastrando y bloques predefinidos.
- Validación en el servidor de cada tipo de dato y control opcional de respuestas repetidas (por ejemplo, un voto por DNI).
- Bases y condiciones en PDF con aceptación obligatoria y registro de la versión aceptada.
- Protección antifraude: límite de envíos por conexión, tiempo mínimo de llenado, campo trampa para bots y captcha de Cloudflare Turnstile opcional.
- Sincronización con Google Sheets: cada formulario escribe en su propia pestaña, con reintentos automáticos si Google falla.

## Cómo funciona

1. **Planilla de destino.** Cada formulario usa la primera planilla conectada que encuentra en este orden: la propia del formulario, la de su área o la de su organización. La organización comparte la planilla con el email de la cuenta de servicio de la app, como Editor.
2. **Publicación.** Al publicar, la app crea en esa planilla una pestaña con el nombre del formulario y sus encabezados, y genera un enlace público corto (`/f/<id>`).
3. **Respuestas.** Cada respuesta se valida y se guarda primero en MySQL, así nunca se pierde aunque Google no responda.
4. **Sincronización.** Un job recurrente (cada 30 segundos) envía las respuestas pendientes a la planilla en lotes de hasta 500 filas. Las columnas se identifican por una clave fija de cada pregunta, así renombrar o agregar preguntas no desordena los datos.
5. **Depuración.** Los datos personales se borran de la base 30 días después de cerrado el formulario, **solo si ya se envió una copia de respaldo** al responsable. Hasta que exista el envío de mails, no se borra nada.

La planilla es la herramienta para ver, filtrar y exportar los datos: la app no tiene pantallas de resultados a propósito, para no cargar el servidor.

En la app, **Ayuda › Cómo funcionan las planillas** (`/ayuda/planillas`) explica estos casos para las personas usuarias.

## Stack

Ruby 3.3, Rails 8.1, MySQL 8, Bootstrap 5 (Sass), Hotwire (Turbo y Stimulus), Solid Queue para jobs, Active Storage con libvips para imágenes y la API de Google Sheets mediante una cuenta de servicio.

## Requisitos

- Ruby 3.3 o superior
- Node.js 22 y Yarn 1.22
- MySQL 8
- libvips (`sudo apt install libvips` en Ubuntu)
- Un proyecto de Google Cloud con la API de Google Sheets habilitada y una cuenta de servicio con clave JSON

## Puesta en marcha

```bash
git clone <repo> formularios_app
cd formularios_app
bundle install
yarn install
```

**Base de datos.** Las credenciales se leen de variables de entorno (por defecto, usuario `root` sin contraseña en `localhost`):

```bash
export DB_USER=root
export DB_PASS=...
bin/rails db:prepare
```

`db:prepare` crea la base principal y la de colas de Solid Queue.

**Credenciales.** Pedí `config/master.key` a quien administra el proyecto (nunca va al repositorio), o generá credenciales nuevas. Después cargá la clave de la cuenta de servicio de Google:

```bash
EDITOR="nano" bin/rails credentials:edit
```

```yaml
google:
  service_account_json: |
    { ...contenido completo del JSON de la cuenta de servicio... }
```

Verificá que quedó bien cargada:

```bash
bin/rails runner 'puts GoogleSheets.service_account_email'
```

**Levantar la app:**

```bash
bin/dev
```

Levanta el servidor web, el compilador de CSS y el procesador de jobs. La app queda en http://localhost:3000.

En desarrollo, el captcha usa automáticamente las claves de prueba de Cloudflare, que siempre aprueban.

## Configuración

| Variable | Para qué | Valor por defecto |
|---|---|---|
| `DB_USER`, `DB_PASS`, `DB_HOST` | Conexión a MySQL | `root`, vacío, `localhost` |
| `PUBLIC_FORM_LIMIT_PER_MINUTE` | Envíos permitidos por IP por minuto | `15` |
| `PUBLIC_FORM_LIMIT_PER_HOUR` | Envíos permitidos por IP por hora | `150` |
| `SUBMISSION_RETENTION_DAYS` | Días después del cierre para depurar datos | `30` |
| `TURNSTILE_SITE_KEY`, `TURNSTILE_SECRET_KEY` | Claves de Cloudflare Turnstile (también pueden ir en las credenciales) | Claves de prueba fuera de producción |
| `RAILS_MASTER_KEY` | Clave para leer las credenciales en el servidor | Sin valor |

Los límites de envío son altos a propósito: muchas redes móviles y wifi públicos comparten una misma IP entre cientos de personas.

## Jobs

Definidos en `config/recurring.yml`:

- `SyncPendingSubmissionsJob`, cada 30 segundos: encola la sincronización de cada formulario con respuestas pendientes.
- `PurgeSyncedSubmissionsJob`, todos los días a las 3: depura los datos de formularios cerrados con respaldo enviado.

Además, `SyncFormJob` sincroniza un formulario puntual (con un solo proceso por formulario a la vez) y `RefreshUniqueDigestsJob` recalcula las huellas del control de repetidos cuando se activa o desactiva.

## Seguridad

- Consultas parametrizadas con Active Record y vistas con escape automático (sin `raw` ni `html_safe`).
- Política de seguridad de contenido (CSP) que solo permite scripts propios y de Cloudflare.
- Las respuestas y los tokens de Google se filtran de los logs.
- Protección contra inyección de fórmulas en Google Sheets.
- El control de repetidos guarda una huella HMAC del dato, no el valor en texto plano. **No cambies `secret_key_base` en producción**: las huellas existentes dejarían de reconocerse.

Antes de cada deploy:

```bash
bin/brakeman
bin/bundler-audit --update
yarn audit
```

## Cuidados con las planillas

- No insertar, borrar ni mover columnas en la pestaña de un formulario: la app escribe cada respuesta en una columna fija.
- Renombrar la pestaña, ordenar, filtrar y agregar otras pestañas sí se puede.
- Si se borra la pestaña, la app la vuelve a crear con las respuestas que todavía estén en la base.
- En un formulario que ya recibe respuestas, no conviene renombrar opciones: las respuestas anteriores conservan el nombre viejo.

## Pendiente antes de producción
- Dockerización del proyecto.
- **Login y roles por organización.** Hoy las pantallas de administración no tienen autenticación. El formulario público, las gracias y la ayuda tienen que quedar accesibles sin sesión
- Cuenta de servicio de Google de producción, creada con una cuenta institucional y con al menos dos propietarios. Sus credenciales van en `bin/rails credentials:edit --environment production`.
- Claves reales de Cloudflare Turnstile para el dominio de producción.
- Configurar el proxy o balanceador para que Rails reciba la IP real de cada visitante (si no, el límite de envíos bloquea a todos).
- `config.assume_ssl` y `config.force_ssl` activos.
- Almacenamiento persistente para imágenes y PDF (disco del servidor o un servicio compatible con S3).
- Solid Queue corriendo en el servidor: `SOLID_QUEUE_IN_PUMA=true` o `bin/jobs` como proceso aparte.
- Envío de mails: copia de respaldo al cerrar un formulario (preferentemente como enlace de descarga con login, no como adjunto).
- Guardar una copia de `config/master.key` y de la clave de producción en un lugar seguro.
