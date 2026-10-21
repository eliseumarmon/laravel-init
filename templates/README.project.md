# {{PROJECT_NAME}}

Aplicación Laravel creada con Laravel Init y Docker Compose.

## Desarrollo local

```bash
make up
```

La aplicación estará disponible en el puerto configurado en `.env`.

```bash
make shell
make migrate
make logs
make down
```

La configuración de infraestructura vive en el `.env` de la raíz. La configuración propia de Laravel, incluida `APP_KEY`, vive en `src/.env`.
