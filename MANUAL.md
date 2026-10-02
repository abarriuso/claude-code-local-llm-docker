# Manual de uso

1. [Requisitos](#1-requisitos)
2. [Instalación](#2-instalación)
3. [Arranque](#3-arranque)
4. [Menú](#4-menú)
5. [Primer uso](#5-primer-uso)
6. [Uso diario](#6-uso-diario)
7. [Modelo local](#7-modelo-local)
8. [Configuración](#8-configuración)
9. [Seguridad](#9-seguridad)
10. [Actualizar, parar y borrar](#10-actualizar-parar-y-borrar)
11. [Solución de problemas](#11-solución-de-problemas)

## 1. Requisitos

| Requisito | Notas |
|---|---|
| Windows 10 22H2 o Windows 11 23H2 (Home o Pro) | Con la virtualización activada en la BIOS. Detalle en [INSTALACION.md](INSTALACION.md#requisitos) |
| WSL2 | `wsl --install` en PowerShell como administrador y reiniciar |
| Docker Desktop | Con *Use WSL 2 based engine* activado |
| Cuenta de Claude o clave de API | Para Claude Code |
| GPU NVIDIA con driver actualizado | Solo para el modelo local |
| LM Studio 0.4.1 o superior | Solo si el modelo local se sirve con LM Studio |

## 2. Instalación

Instalación completa desde cero (WSL2, Docker Desktop, Git, GPU, LM Studio): [INSTALACION.md](INSTALACION.md).

Con Git:

```powershell
git clone https://github.com/abarriuso/claude-code-local-llm-docker.git
cd claude-code-local-llm-docker
```

Sin Git: en GitHub, *Code → Download ZIP*, y descomprimir.

## 3. Arranque

1. Abrir Docker Desktop y esperar a *Engine running*.
2. Ejecutar `iniciar.cmd` (doble clic o desde la terminal):

```powershell
.\iniciar.cmd              # modelo local en LM Studio, o sin modelo local
.\iniciar.cmd -LlamaCpp    # modelo local en llama.cpp (Docker)
```

El script comprueba la instalación, abre Docker Desktop si está cerrado, crea `.env` si no existe, arranca el entorno, espera a que el cortafuegos esté activo y abre el menú. La primera vez construye la imagen y tarda 5-10 minutos.

## 4. Menú

El menú se queda en la ventana de `iniciar.cmd`. **Cada opción se abre en una pestaña nueva** de Windows Terminal (o en una ventana nueva si no está instalado), así se pueden usar varias herramientas a la vez.

| Opción | Qué abre |
|---|---|
| 1 | Claude Code con la suscripción de Claude |
| 2 | Claude Code con la API de Anthropic (`ANTHROPIC_API_KEY`) |
| 3 | OpenCode con el modelo local |
| 4 | OpenCode con la API de Anthropic (`ANTHROPIC_API_KEY`) |
| 5 | Lista de modelos locales disponibles |
| 6 | Terminal del entorno (git, gh, npm…) |
| 7 | Para el entorno |
| 0 | Cierra el menú; el entorno sigue encendido |

La cabecera muestra el modelo local detectado y si la clave de API está configurada. Si una opción no se puede usar todavía (falta la clave o el modelo), el menú lo explica en vez de abrirla.

Dentro del entorno (por ejemplo, en la terminal de VS Code o en la opción 6) existe el mismo menú en modo texto: `ia`.

Atajos de `ia`:

```bash
ia 1          # abre la opción 1 directamente
ia 3 -c       # los argumentos extra pasan a la herramienta (aquí: continuar la última sesión)
ia -h         # ayuda
```

## 5. Primer uso

Dentro del contenedor (`docker compose exec -u node workspace bash`, o la terminal de VS Code):

```bash
gh auth login                                  # GitHub: código de un solo uso en el navegador
cd /workspace
gh repo clone <usuario>/<repo>                 # o git clone <url>
cd <repo>
ia 1                                           # Claude Code
```

La primera vez, Claude Code muestra una URL de inicio de sesión: abrirla en el navegador de Windows, iniciar sesión y pegar el código.

Las sesiones de Claude Code, OpenCode y GitHub se conservan entre reinicios.

## 6. Uso diario

Con Docker Desktop abierto, desde la carpeta del repositorio:

Ejecutar `iniciar.cmd`: si el entorno ya está en marcha, abre el menú en segundos.

Sin el menú, desde la carpeta del repositorio:

```powershell
docker compose exec -u node workspace ia       # menú en modo texto
docker compose exec -u node workspace bash     # terminal
```

**Abrir en VS Code:**

1. Instalar la extensión *Dev Containers*.
2. *File → Open Folder* → carpeta del repositorio.
3. *Reopen in Container* (aviso abajo a la derecha, o `F1` → *Dev Containers: Reopen in Container*).

VS Code se abre dentro del entorno en `/workspace`, con el usuario `node`. La terminal integrada ya está dentro: `ia` abre el menú.

**Servidores de desarrollo:** arrancarlos escuchando en `0.0.0.0` y abrirlos en Windows:

| Puerto | URL |
|---|---|
| 3000 | http://localhost:3000 |
| 5173 | http://localhost:5173 |
| 8080 | http://localhost:8080 |

Ejemplo: `npm run dev -- --host 0.0.0.0 --port 5173`. Otros puertos se añaden en `docker-compose.yml`.

## 7. Modelo local

### LM Studio

1. Descargar un modelo en *Discover* (ver tabla de modelos).
2. Cargarlo con contexto 32768 y *GPU offload* al máximo.
3. *Developer → Start Server* (puerto 1234).
4. Arrancar con `.\iniciar.cmd`.

### llama.cpp

1. Comprobar que Docker ve la GPU:
   ```powershell
   docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
   ```
2. Elegir el modelo en `.env` (`LLAMACPP_HF_REPO`).
3. Arrancar con `.\iniciar.cmd -LlamaCpp`. El primer arranque descarga el modelo:
   ```powershell
   docker compose logs -f llamacpp
   ```

### Modelos recomendados

| GPU | RAM | `LLAMACPP_HF_REPO` | Notas |
|---|---|---|---|
| 6–8 GB | 16 GB | `unsloth/Qwen3.5-9B-GGUF:Q4_K_M` | Entero en la GPU |
| 8–16 GB | 32 GB | `unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_M` | `LLAMACPP_CPU_MOE=true` |
| 24 GB o más | — | `unsloth/Qwen3.6-27B-GGUF:Q4_K_M` | Entero en la GPU |

En LM Studio, buscar el mismo modelo en *Discover*. Para modelos MoE en GPUs pequeñas, activar la opción de mantener los expertos en la CPU.

## 8. Configuración

Fichero `.env` en la carpeta del repositorio:

| Variable | Descripción |
|---|---|
| `LOCAL_URL` | Servidor del modelo local. Lo fija `iniciar.cmd` |
| `LOCAL_MODEL` | Modelo local a usar. Vacío = el primero disponible |
| `LLAMACPP_HF_REPO` | Modelo GGUF de Hugging Face (`usuario/repo:cuantización`) |
| `LLAMACPP_CTX` | Tamaño de contexto (recomendado 32768) |
| `LLAMACPP_CPU_MOE` | `true` para mantener los expertos MoE en la RAM |
| `ANTHROPIC_API_KEY` | Clave de API de Anthropic (opciones 2 y 4) |
| `CLAUDE_MODEL` | Modelo de Claude en OpenCode. Vacío = elegir con `/models` |
| `GIT_USER_NAME`, `GIT_USER_EMAIL` | Identidad de git dentro del contenedor |
| `FIREWALL` | `on` (por defecto) u `off` |
| `FIREWALL_ALLOW` | Dominios, IPs o rangos extra permitidos, separados por comas |
| `WORKSPACE_MEMORY` | Memoria máxima del contenedor (por defecto `4g`) |
| `WORKSPACE_CPUS` | Núcleos máximos del contenedor (por defecto `2`) |

Aplicar cambios:

```powershell
docker compose up -d                       # LM Studio
docker compose --profile llamacpp up -d    # llama.cpp
```

## 9. Seguridad

| Medida | Efecto |
|---|---|
| Cortafuegos de salida | El contenedor solo puede conectarse a los destinos permitidos. El resto se rechaza |
| Arranque seguro | Si el cortafuegos no se aplica, el contenedor no arranca |
| Usuario sin privilegios | Claude Code y OpenCode se ejecutan como `node`, sin permisos de administrador |
| Contenedor endurecido | Sin capacidades de Linux salvo las mínimas, sin escalada de privilegios, con límites de memoria, CPU y procesos |
| Aislamiento de archivos | Los agentes solo ven `/workspace` y su carpeta personal, no el disco de Windows |
| Puertos locales | Los servidores de desarrollo solo son accesibles desde el propio PC |

Destinos permitidos por defecto: Anthropic y Claude, npm, GitHub, OpenCode, VS Code, el modelo local (LM Studio o llama.cpp) y DNS.

Para permitir otros destinos (por ejemplo, la API de un proyecto o un CDN de paquetes):

```
FIREWALL_ALLOW=api.miproyecto.com,cdn.jsdelivr.net
```

Y aplicar con `.\iniciar.cmd`. Las direcciones se resuelven al arrancar: si un servicio cambia de IP y deja de conectar, reiniciar con `.\iniciar.cmd`.

## 10. Actualizar, parar y borrar

| Tarea | Comando |
|---|---|
| Actualizar el repositorio | `git pull` y después `.\iniciar.cmd` |
| Actualizar Claude Code y OpenCode | `docker compose build --pull` y después `.\iniciar.cmd` |
| Actualizar llama.cpp | `docker compose --profile llamacpp pull` |
| Parar | `docker compose --profile llamacpp stop` |
| Borrar contenedores | `docker compose --profile llamacpp down` |
| Borrar todo, incluidos sesiones, proyectos y modelos | `docker compose --profile llamacpp down -v` |

Los proyectos de `/workspace` viven en un volumen de Docker: subir los cambios con git antes de borrar.

## 11. Solución de problemas

| Problema | Solución |
|---|---|
| `failed to connect to the docker API` | Abrir Docker Desktop y esperar a *Engine running* |
| Docker en modo contenedores de Windows | Icono de Docker → *Switch to Linux containers* |
| `running scripts is disabled` | Usar `iniciar.cmd` en lugar de `iniciar.ps1` |
| `port is already allocated` | Cerrar el programa que usa el puerto o cambiarlo en `docker-compose.yml` |
| Sin servidor de modelos (LM Studio) | *Developer → Start Server*. Si persiste, activar *Serve on Local Network* |
| Sin servidor de modelos (llama.cpp) | El modelo aún se está descargando: `docker compose logs -f llamacpp` |
| `could not select device driver "nvidia"` | Actualizar el driver NVIDIA y Docker Desktop |
| Memoria insuficiente en llama.cpp | Bajar `LLAMACPP_CTX`, activar `LLAMACPP_CPU_MOE` o usar una cuantización menor |
| El modelo local no usa herramientas o se corta | Subir el contexto a 32768 o usar un modelo mayor |
| `entrypoint.sh: no such file` | `docker compose build --no-cache` |
| El entorno no arranca (`dependency failed` o `unhealthy`) | Ver el motivo con `docker compose logs workspace` |
| Una herramienta no conecta (`Connection refused`, `EHOSTUNREACH`) | El cortafuegos bloquea ese destino: añadirlo a `FIREWALL_ALLOW` |
| VS Code no termina de abrir el contenedor | Añadir a `FIREWALL_ALLOW` el dominio que aparezca en el registro de *Dev Containers* |
