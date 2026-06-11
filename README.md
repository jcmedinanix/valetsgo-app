# ValetsGo DevOps — Arquitectura de despliegue automatizado

> Implementación de una arquitectura DevOps basada en IaC, contenedores y CI/CD para ValetsGo S.A.C.
> Universidad Católica Santo Toribio de Mogrovejo — Facultad de Ingeniería — 2026
> Autor: Juan Carlos Medina Ruiz

---

## ¿Qué incluye este proyecto?

Este repositorio contiene la arquitectura DevOps completa que transforma el proceso de despliegue manual de ValetsGo S.A.C. (8–12 pasos, 45–60 minutos) en un proceso automatizado activado por un `git push`. Incluye:

| Componente | Herramienta | Propósito |
|---|---|---|
| Infraestructura como código | Terraform | Aprovisiona el servidor en OCI automáticamente |
| Contenedorización | Docker + Docker Compose | Empaqueta y orquesta todos los servicios |
| CI/CD | GitHub Actions | Construye, publica y despliega en cada push |
| Proxy inverso | Nginx | Enruta el tráfico hacia los servicios |
| Monitoreo | Uptime Kuma | Vigilancia 24/7 con alertas automáticas |
| Dashboard de operaciones | Node.js + Express | Gestión visual de contenedores y rollback |

---

## Arquitectura del sistema

```
Internet
    ↓
Nginx (puerto 80)
    ├── /              → valetsgo-app (puerto 3000)
    ├── /dashboard     → valetsgo-dashboard (puerto 4000)
    └── /health        → valetsgo-app/health

Uptime Kuma (puerto 3001) — monitoreo independiente

Pipeline CI/CD (GitHub Actions)
    push a main → build imagen → push a Docker Hub → deploy via SSH
```

---

## Requisitos previos

### Lo que necesita tener la empresa antes de instalar

**Servidor:**
- Linux Ubuntu 22.04 o superior
- Docker instalado (`curl -fsSL https://get.docker.com | sh`)
- Docker Compose instalado (`sudo apt install docker-compose`)
- Puerto 80, 3001 y 4000 abiertos en el firewall

**Cuentas:**
- Cuenta en [GitHub](https://github.com) (gratuita)
- Cuenta en [Docker Hub](https://hub.docker.com) (gratuita)
- Servidor Linux accesible por SSH (puede ser OCI Always Free, DigitalOcean, AWS, etc.)

**En el servidor, crear la carpeta de trabajo:**
```bash
mkdir ~/valetsgo-app
```

---

## Instalación paso a paso

### Paso 1 — Obtener el repositorio

```bash
git clone https://github.com/jcmedinanix/valetsgo-app.git mi-proyecto
cd mi-proyecto
```

### Paso 2 — Personalizar las variables de la empresa

Editar `docker-compose.yml` y reemplazar los valores marcados con `# CAMBIAR`:

```yaml
# En el servicio valetsgo-app:
image: su-usuario-dockerhub/su-app:latest   # CAMBIAR

# En el servicio dashboard, variables de entorno:
DASHBOARD_USER=admin                          # CAMBIAR — usuario de acceso al dashboard
DASHBOARD_PASS=su-password-seguro            # CAMBIAR — contraseña segura
DOCKER_IMAGE=su-usuario-dockerhub/su-app     # CAMBIAR — misma imagen que arriba
```

Editar `.github/workflows/deploy.yml` y reemplazar:

```yaml
# Líneas de tags en "Build y push imagen app":
jcmedinanix/valetsgo-app   →   su-usuario-dockerhub/su-app

# Líneas de tags en "Build y push imagen dashboard":
jcmedinanix/valetsgo-dashboard   →   su-usuario-dockerhub/su-dashboard
```

### Paso 3 — Configurar los secrets en GitHub

Ir al repositorio en GitHub → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Agregar estos 5 secrets:

| Secret | Valor |
|---|---|
| `DOCKERHUB_USERNAME` | Tu usuario de Docker Hub |
| `DOCKERHUB_TOKEN` | Token de acceso de Docker Hub (Account Settings → Security) |
| `SSH_HOST` | IP pública del servidor |
| `SSH_USER` | Usuario SSH del servidor (ej: `ubuntu`) |
| `SSH_KEY` | Contenido de la llave privada SSH (ej: contenido de `~/.ssh/id_rsa`) |

### Paso 4 — Primer despliegue

Hacer cualquier cambio en el código y hacer push:

```bash
git add .
git commit -m "primer despliegue"
git push origin main
```

GitHub Actions se activa automáticamente, construye las imágenes, las publica en Docker Hub y despliega en el servidor. El proceso tarda aproximadamente 3–5 minutos.

### Paso 5 — Verificar que todo esté corriendo

Desde el servidor:

```bash
docker ps
```

Deben aparecer 4 contenedores en estado `Up`:
- `valetsgo-nginx`
- `valetsgo-app`
- `valetsgo-dashboard`
- `valetsgo-uptime`

---

## Uso del sistema — guía para el operador

### Acceder al dashboard de operaciones

Abrir en el navegador:
```
http://IP-DEL-SERVIDOR/dashboard
```

Credenciales por defecto (cambiar en `docker-compose.yml`):
- **Usuario:** `admin`
- **Contraseña:** `valetsgo2026`

### Funciones disponibles en el dashboard

**Ver estado de contenedores**
La sección "Contenedores" muestra en tiempo real el nombre, imagen, estado y permite reiniciar cada contenedor con un clic.

**Ver logs**
Seleccionar un contenedor en el selector de la sección "Logs del contenedor". Se muestran las últimas 100 líneas en tiempo real.

**Ejecutar rollback**
Cuando un despliegue nuevo genera problemas:
1. En "Rollback de versión" seleccionar el contenedor `valetsgo-app`
2. Elegir la versión anterior en el selector (muestra fecha de publicación)
3. Click en "⚠ Ejecutar rollback"
4. Confirmar en el diálogo
5. Esperar 20–40 segundos — el contenedor se recrea con la versión anterior

**Ver historial de operaciones**
La sección "Historial" registra todas las acciones: reinicios, rollbacks y sus resultados con fecha, hora y usuario.

### Monitoreo con Uptime Kuma

Acceder en:
```
http://IP-DEL-SERVIDOR:3001
```

Desde ahí configurar monitores para cada servicio y recibir alertas por email, Telegram o Slack cuando algún servicio caiga.

---

## Cómo hacer un nuevo despliegue de la aplicación

Cualquier cambio en el código se despliega automáticamente:

```bash
# Hacer cambios en el código
git add .
git commit -m "descripcion del cambio"
git push origin main
```

GitHub Actions hace todo lo demás: construye la nueva imagen, la publica en Docker Hub con el SHA del commit como tag y despliega en el servidor.

---

## Impacto medido — antes vs después

| Indicador | Proceso manual | Con esta arquitectura |
|---|---|---|
| Tiempo de despliegue | 45–60 minutos | ~3 minutos |
| Pasos manuales | 8–12 pasos sobre el servidor | 1 (`git push`) |
| Tiempo de rollback ante fallo | 2–4 horas | ~30 segundos |
| Disponibilidad monitoreada | Sin monitoreo | 24/7 con alertas |
| Reproducibilidad del entorno | Depende de un técnico | Cualquier persona con acceso al repo |

---

## Estructura del repositorio

```
valetsgo-app/
├── .github/
│   └── workflows/
│       └── deploy.yml          ← pipeline CI/CD completo
├── dashboard/                  ← dashboard de operaciones (valor agregado)
│   ├── middleware/
│   │   ├── auth.js             ← autenticación por sesión
│   │   └── logger.js           ← registro de operaciones
│   ├── public/
│   │   ├── index.html          ← interfaz principal del dashboard
│   │   ├── login.html          ← pantalla de acceso
│   │   ├── style.css           ← estilos
│   │   └── app.js              ← lógica del frontend
│   ├── routes/
│   │   ├── auth.js             ← login y logout
│   │   ├── containers.js       ← listar y reiniciar contenedores
│   │   ├── logs.js             ← obtener logs de contenedores
│   │   ├── rollback.js         ← ejecutar rollback de versiones
│   │   └── history.js          ← historial de operaciones
│   ├── Dockerfile              ← imagen del dashboard
│   └── server.js               ← servidor Express
├── Dockerfile                  ← imagen de la aplicación principal
├── docker-compose.yml          ← orquestación de los 4 servicios
├── nginx.conf                  ← configuración del proxy inverso
├── index.js                    ← aplicación Node.js principal
└── package.json
```

---

## Solución de problemas frecuentes

**Los contenedores no levantan después del deploy**
```bash
cd ~/valetsgo-app
docker-compose down
docker container prune -f
docker-compose pull
docker-compose up -d
```

**El dashboard no muestra los contenedores**
Cerrar sesión y volver a ingresar — la cookie de sesión puede haber expirado.

**Error "No such container" en el rollback**
Verificar el nombre exacto del contenedor:
```bash
docker ps --format '{{.Names}}'
```
Si el nombre tiene un prefijo como `abc123_valetsgo-app`, detenerlo, eliminarlo y recrearlo:
```bash
docker stop abc123_valetsgo-app
docker rm abc123_valetsgo-app
docker-compose up -d valetsgo-app
```

**El pipeline falla en GitHub Actions**
Ir a la pestaña Actions del repositorio, abrir el workflow fallido y revisar el paso que marcó el error en rojo.

---

## Tecnologías utilizadas

- **Node.js 18** — runtime de la aplicación y del dashboard
- **Docker / Docker Compose** — contenedorización y orquestación
- **Nginx Alpine** — proxy inverso
- **GitHub Actions** — pipeline CI/CD
- **Docker Hub** — registro de imágenes
- **Uptime Kuma** — monitoreo de disponibilidad
- **Oracle Cloud Infrastructure (Always Free)** — servidor de producción
- **Express.js** — framework del dashboard de operaciones
- **Dockerode** — cliente Docker para Node.js

---

## Licencia

Proyecto desarrollado como trabajo de investigación de tesis.
Universidad Católica Santo Toribio de Mogrovejo — Chiclayo, 2026.
