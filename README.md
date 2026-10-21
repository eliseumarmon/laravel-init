# Laravel Init

Plantilla mínima para iniciar aplicaciones Laravel con PHP 8.5-FPM, Nginx y MySQL 8.4 LTS en Docker Compose. Está pensada para crear proyectos locales aislados, con puertos y credenciales configurables desde un único archivo de infraestructura.

## Requisitos

- Git
- Docker Engine o Docker Desktop con Docker Compose v2
- Make

Está orientada a Linux, macOS y WSL.

## Crear un proyecto

La opción recomendada es activar este repositorio como **GitHub Template Repository** y usar **Use this template**. El repositorio resultante ya tiene un historial y un remoto propios.

También se puede crear desde GitHub CLI:

```bash
gh repo create mi-proyecto --template eliseumarmon/laravelinit --private --clone
cd mi-proyecto
```

Como alternativa, se puede clonar directamente:

```bash
git clone https://github.com/eliseumarmon/laravelinit.git mi-proyecto
cd mi-proyecto
```

## Configuración e inicio

1. Crea la configuración local y personalízala, especialmente si tendrás varios proyectos activos:

   ```bash
   cp .env.example .env
   ```

2. Edita `.env`. `PROJECT_NAME` identifica los recursos de Compose; `HTTP_PORT` y `MYSQL_PORT` son puertos del host. MySQL siempre está disponible para Laravel como `mysql:3306` dentro de Docker.

3. Crea Laravel, inicia los servicios y ejecuta migraciones:

   ```bash
   make init
   ```

La aplicación estará disponible en `http://127.0.0.1:HTTP_PORT` (por defecto, `http://127.0.0.1:8080`).

`make init` crea `.env` automáticamente si falta, pero revisarlo antes evita conflictos de nombre, puertos o credenciales. Por seguridad, nunca sobrescribe contenido existente en `src` ni elimina volúmenes Docker.

## Variables de infraestructura

| Variable | Propósito | Valor de ejemplo |
| --- | --- | --- |
| `PROJECT_NAME` | Nombre de proyecto Docker Compose | `laravel` |
| `PHP_VERSION` | Versión de PHP probada | `8.5` |
| `HOST_UID` / `HOST_GID` | UID/GID con que Compose ejecuta PHP y crea archivos | `1000` |
| `HTTP_PORT` | Puerto HTTP local | `8080` |
| `MYSQL_PORT` | Puerto MySQL local | `3307` |
| `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD` | Base de datos local | Valores de desarrollo |
| `XDEBUG_MODE` | Xdebug (`off` o `debug`) | `off` |

El `.env` de la raíz controla Docker. `src/.env` pertenece a Laravel y contiene configuración de aplicación como `APP_KEY`. Compose inyecta los valores `DB_*` de la raíz en PHP-FPM y Artisan, por lo que no hay que configurar manualmente la conexión MySQL en `src/.env` para trabajar dentro de Docker.

Cuando `make init` crea un `.env` nuevo, detecta `HOST_UID` y `HOST_GID` mediante `id`; Compose los aplica mediante `user: UID:GID` al contenedor PHP. Si creas el archivo manualmente, ajusta ambos valores si tu usuario no usa `1000:1000`.

Xdebug está desactivado de forma predeterminada. Con `XDEBUG_MODE=debug`, se conecta al depurador del host mediante `host.docker.internal:9003`.

## Comandos habituales

| Comando | Acción |
| --- | --- |
| `make up` | Inicia los servicios y espera a que estén listos. |
| `make down` | Detiene servicios sin borrar la base de datos. |
| `make shell` | Abre Bash en el contenedor PHP. |
| `make logs` | Sigue los registros de todos los servicios. |
| `make migrate` | Ejecuta migraciones Laravel. |

Si una inicialización falla después de crear Laravel, corrige la causa y usa `make up` o `make migrate`; no ejecutes de nuevo `make init` sobre una aplicación ya creada.

## Clones directos y Git

Un repositorio generado con GitHub Template no necesita ninguna acción adicional: conserva su remoto e historial independientes.

Un clon directo conserva el historial de Laravel Init. Tras completar `make init`, puedes sustituirlo de forma explícita:

```bash
make detach-template CONFIRM_DETACH=YES
git add -A
git commit -m "Initial Laravel application"
```

El comando sólo se ejecuta cuando `origin` apunta exactamente a `eliseumarmon/laravelinit` y no hay commits locales adicionales. Conserva los archivos del proyecto, elimina el historial heredado y crea un repositorio nuevo sin remoto.

## Publicar como plantilla

En GitHub, abre **Settings → General** del repositorio y marca **Template repository**. Es una acción manual de publicación; no modifica la configuración local del proyecto.
