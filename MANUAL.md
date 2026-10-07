# Manual de uso

1. [Requisitos](#1-requisitos)
2. [Instalación](#2-instalación)
3. [Arranque](#3-arranque)
4. [Proyectos](#4-proyectos)
5. [Menú del proyecto](#5-menú-del-proyecto)
6. [Primer uso](#6-primer-uso)
7. [Uso diario](#7-uso-diario)
8. [Modelo local](#8-modelo-local)
9. [Configuración](#9-configuración)
10. [Seguridad](#10-seguridad)
11. [Actualizar, parar y borrar](#11-actualizar-parar-y-borrar)
12. [Solución de problemas](#12-solución-de-problemas)

## 1. Requisitos

| Requisito | Notas |
|---|---|
| Windows 10 22H2 o Windows 11 23H2 (Home o Pro) | Con la virtualización activada en la BIOS. Detalle en [INSTALACION.md](INSTALACION.md#requisitos) |
| Docker Desktop | Con *Use WSL 2 based engine* activado (viene así por defecto) |
| Cuenta de Claude (Pro, Max o Team) o clave de API | Para Claude Code. OpenCode funciona sin ellas |
| GPU NVIDIA con driver actualizado | Solo para el modelo local |
| LM Studio 0.4.1 o superior | Solo si el modelo local se sirve con LM Studio |
| VS Code | Opcional, para la opción *VS Code* del menú |

No hace falta instalar Git, Node.js, Python ni ninguna herramienta más: están dentro del entorno.

## 2. Instalación

Instalación completa desde cero: [INSTALACION.md](INSTALACION.md).

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

El script comprueba la instalación, abre Docker Desktop si está cerrado, crea `.env` si no existe y prepara el entorno: descarga la imagen ya construida o, si no puede, la construye en el PC (5-10 minutos la primera vez). Después muestra los proyectos.

## 4. Proyectos

Cada proyecto vive en **su propio contenedor**, con sus archivos, su historial de git y sus puertos. Un agente que trabaja en un proyecto no puede ver ni tocar los demás.

Lo que comparten todos los proyectos:

- La imagen (Claude Code, OpenCode y las herramientas): se descarga una sola vez.
- Las sesiones de Claude, OpenCode y GitHub: se inicia sesión una vez y vale para todos.
- Los modelos de llama.cpp.

La pantalla principal de `iniciar.cmd`:

```
   TUS PROYECTOS
     1  tienda                  apagado
     2  web                     encendido   http://localhost:3001

     N  Nuevo proyecto          Vacío o a partir de un repositorio de GitHub
     B  Borrar un proyecto      Avisa si hay cambios sin subir a GitHub
     A  Actualizar              Últimas versiones de Claude Code y OpenCode
     P  Apagar todo             Apaga todos los proyectos. No se pierde nada
     0  Salir                   Los proyectos encendidos siguen funcionando
```

- **Abrir un proyecto:** escribir su número. Si estaba apagado, se enciende en unos segundos.
- **Nuevo proyecto (N):** pide un nombre (minúsculas, números y guiones) y, opcionalmente, la dirección de un repositorio. Si el repositorio es privado y GitHub no está conectado, ofrece conectarlo. Un proyecto vacío empieza con git y un `CLAUDE.md` de plantilla para los agentes.
- **Borrar (B):** borra el contenedor y los archivos del proyecto. Antes avisa si hay cambios sin guardar o sin subir a GitHub, y pide escribir el nombre otra vez.

**Puertos:** dentro de cada proyecto los servidores de desarrollo usan siempre 3000, 5173 y 8080. En Windows, cada proyecto los publica en puertos distintos para que puedan funcionar a la vez: el primer proyecto en 3001, 5174 y 8081, el segundo en 3002, 5175 y 8082, etc. El menú del proyecto muestra sus direcciones.

**Proyecto `general`:** si usabas una versión anterior de este repositorio, tus archivos de `/workspace` aparecen como el proyecto `general`, con los puertos de siempre (3000, 5173, 8080).

## 5. Menú del proyecto

Las herramientas se abren en una **pestaña nueva** de Windows Terminal (o en una ventana nueva si no está instalado) y el menú sigue disponible, así se pueden usar varias a la vez.

| Opción | Qué abre |
|---|---|
| **Trabajar con IA** | |
| 1 Claude Code | Claude Code con tu cuenta de Claude. Pide permiso antes de cada cambio o comando |
| 2 Claude Code autónomo | Claude Code sin pedir permiso en cada paso (`--dangerously-skip-permissions`). Más rápido; seguro porque el proyecto está aislado y con cortafuegos. Revisa los cambios al final con git |
| 3 OpenCode | OpenCode sin modelo fijo: eliges proveedor y modelo dentro con `/connect` y `/models`. Incluye modelos gratuitos (OpenCode Zen) y, si hay `ANTHROPIC_API_KEY`, los de Anthropic |
| 4 OpenCode local | OpenCode con el modelo de LM Studio o llama.cpp. Gratis y el código no sale del PC |
| **Herramientas** | |
| 5 Terminal | Línea de comandos del proyecto (git, gh, npm, python…) |
| 6 VS Code | Abre el proyecto en VS Code, conectado al contenedor. Instala sola la extensión *Dev Containers* |
| 7 Conectar GitHub | Inicia sesión en GitHub con un código de un solo uso. Necesario para repositorios privados y para subir cambios |
| **Avanzado** | |
| 8 Claude Code con API | Claude Code pagando por uso con `ANTHROPIC_API_KEY` |
| 9 Modelos locales | Lista los modelos disponibles en LM Studio o llama.cpp |
| 0 Volver | Vuelve a la lista de proyectos. El proyecto sigue encendido |

Dentro del proyecto (en la terminal o en VS Code) existe el mismo menú en modo texto: `ia`. También se puede usar con nombres:

```bash
ia claude        # Claude Code
ia auto          # Claude Code autónomo
ia opencode      # OpenCode, eligiendo proveedor y modelo
ia local         # OpenCode con el modelo local
ia github        # conectar GitHub
ia claude -c     # los argumentos extra pasan a la herramienta (aquí: continuar la última conversación)
ia -h            # ayuda
```

## 6. Primer uso

1. `iniciar.cmd` → **N** → nombre del proyecto → Enter (vacío) o la dirección de un repositorio.
2. En el menú del proyecto, **1** (Claude Code). La primera vez muestra una URL de inicio de sesión: abrirla en el navegador de Windows, iniciar sesión y pegar el código.
3. Para subir el trabajo a GitHub: opción **7** (Conectar GitHub) una vez.

Las sesiones de Claude Code, OpenCode y GitHub se conservan entre reinicios y valen para todos los proyectos.

Los agentes leen el archivo `CLAUDE.md` del proyecto al empezar: rellénalo (o pídeles que lo hagan con `/init`). Además conocen las reglas del entorno (puertos, cortafuegos, sin `sudo`) sin que haya que explicárselas. Más consejos en [Cómo trabajar con agentes](GUIA-AGENTES.md).

## 7. Uso diario

Con Docker Desktop abierto: ejecutar `iniciar.cmd` y elegir el proyecto. Si el entorno ya está preparado, tarda segundos.

Sin el menú, desde la carpeta del repositorio:

```powershell
docker exec -it -u node entorno-ia-web-workspace-1 ia     # menú del proyecto "web"
docker exec -it -u node entorno-ia-web-workspace-1 bash   # terminal del proyecto "web"
```

Los contenedores se llaman `entorno-ia-<proyecto>-workspace-1` y aparecen agrupados en Docker Desktop (*Containers*), donde también se pueden ver sus registros, encender y apagar.

**Servidores de desarrollo:** arrancarlos escuchando en `0.0.0.0` y en el puerto 3000, 5173 u 8080. Abrirlos en Windows con la dirección que muestra el menú del proyecto. Ejemplo:

```bash
npm run dev -- --host 0.0.0.0 --port 5173     # en el proyecto 1 se abre en http://localhost:5174
```

**VS Code:** la opción 6 abre el proyecto conectado a su contenedor, con el usuario `node` en `/workspace`. La terminal integrada ya está dentro: `ia` abre el menú. El archivo `.devcontainer/devcontainer.json` del repositorio abre el proyecto `general`.

## 8. Modelo local

### LM Studio

1. Descargar un modelo en *Discover* (ver tabla de modelos).
2. Cargarlo con contexto 32768 y *GPU offload* al máximo.
3. *Developer → Start Server* (puerto 1234).
4. Arrancar con `.\iniciar.cmd` y usar la opción **4** del proyecto.

### llama.cpp

1. Comprobar que Docker ve la GPU:
   ```powershell
   docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
   ```
2. Elegir el modelo en `.env` (`LLAMACPP_HF_REPO`).
3. Arrancar con `.\iniciar.cmd -LlamaCpp`. Un único llama.cpp sirve a todos los proyectos. El primer arranque descarga el modelo:
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

## 9. Configuración

Fichero `.env` en la carpeta del repositorio. Vale para todos los proyectos:

| Variable | Descripción |
|---|---|
| `LOCAL_URL` | Servidor del modelo local. Lo fija `iniciar.cmd` |
| `LOCAL_MODEL` | Modelo local a usar. Vacío = el primero disponible |
| `LLAMACPP_HF_REPO` | Modelo GGUF de Hugging Face (`usuario/repo:cuantización`) |
| `LLAMACPP_CTX` | Tamaño de contexto (recomendado 32768) |
| `LLAMACPP_CPU_MOE` | `true` para mantener los expertos MoE en la RAM |
| `ANTHROPIC_API_KEY` | Clave de API de Anthropic (opción 8, y Anthropic en OpenCode) |
| `CLAUDE_MODEL` | Modelo de Claude con el que arranca OpenCode si hay clave de API. Vacío = elegir con `/models` |
| `GIT_USER_NAME`, `GIT_USER_EMAIL` | Identidad de git dentro de los proyectos |
| `FIREWALL` | `on` (por defecto) u `off` |
| `FIREWALL_ALLOW` | Dominios, IPs o rangos extra permitidos, separados por comas |
| `WORKSPACE_MEMORY` | Memoria máxima de cada proyecto (por defecto `4g`) |
| `WORKSPACE_CPUS` | Núcleos máximos de cada proyecto (por defecto `2`) |
| `IMAGEN` | Imagen del entorno. Por defecto, la publicada por este repositorio |

Los cambios se aplican al volver a abrir el proyecto desde `iniciar.cmd`.

## 10. Seguridad

| Medida | Efecto |
|---|---|
| Un contenedor por proyecto | Cada agente solo ve los archivos de su proyecto, no los demás ni el disco de Windows |
| Cortafuegos de salida | El contenedor solo puede conectarse a los destinos permitidos. El resto se rechaza |
| Arranque seguro | Si el cortafuegos no se aplica, el contenedor no arranca |
| Usuario sin privilegios | Claude Code y OpenCode se ejecutan como `node`, sin permisos de administrador |
| Contenedor endurecido | Sin capacidades de Linux salvo las mínimas, sin escalada de privilegios, con límites de memoria, CPU y procesos |
| Puertos locales | Los servidores de desarrollo solo son accesibles desde el propio PC |

Destinos permitidos por defecto: Anthropic y Claude, GitHub, npm, PyPI, OpenCode y los proveedores más comunes (OpenAI, OpenRouter, GitHub Copilot, Google Gemini), VS Code, el modelo local (LM Studio o llama.cpp) y DNS.

Lo que se comparte entre proyectos: las sesiones (Claude, OpenCode, GitHub) y el historial de conversaciones de los agentes, que viven en la carpeta personal común.

Para permitir otros destinos (por ejemplo, la API de un proyecto o un CDN de paquetes):

```
FIREWALL_ALLOW=api.miproyecto.com,cdn.jsdelivr.net
```

Y aplicar abriendo el proyecto de nuevo desde `iniciar.cmd`. Las direcciones se resuelven al arrancar: si un servicio cambia de IP y deja de conectar, apagar y volver a abrir el proyecto.

## 11. Actualizar, parar y borrar

| Tarea | Cómo |
|---|---|
| Actualizar Claude Code, OpenCode y las herramientas | `iniciar.cmd` → **A** |
| Actualizar este repositorio | `git pull` (o descargar el ZIP de nuevo) y ejecutar `iniciar.cmd`. Los proyectos se conservan |
| Apagar todos los proyectos | `iniciar.cmd` → **P** |
| Borrar un proyecto | `iniciar.cmd` → **B** |
| Actualizar llama.cpp | `docker compose --profile llamacpp pull` |

Los archivos de cada proyecto viven en un volumen de Docker (`entorno-ia-<proyecto>_workspace`): súbelos a GitHub para tenerlos a salvo.

**Borrar todo** (proyectos, sesiones y modelos), desde la carpeta del repositorio:

```powershell
docker ps -aq --filter "name=entorno-ia" | ForEach-Object { docker rm -f $_ }
docker volume ls -q --filter "name=entorno-ia" | ForEach-Object { docker volume rm $_ }
```

No uses `docker compose down -v` con el proyecto de un nombre (`-p entorno-ia-…`): intentaría borrar también las sesiones y los modelos compartidos.

## 12. Solución de problemas

| Problema | Solución |
|---|---|
| `failed to connect to the docker API` | Abrir Docker Desktop y esperar a *Engine running* |
| Docker en modo contenedores de Windows | Icono de Docker → *Switch to Linux containers* |
| `running scripts is disabled` | Usar `iniciar.cmd` en lugar de `iniciar.ps1` |
| `port is already allocated` | Otro programa usa el puerto que muestra el error: cerrarlo |
| Sin servidor de modelos (LM Studio) | *Developer → Start Server*. Si persiste, activar *Serve on Local Network* |
| Sin servidor de modelos (llama.cpp) | El modelo aún se está descargando: `docker compose logs -f llamacpp` |
| `could not select device driver "nvidia"` | Actualizar el driver NVIDIA y Docker Desktop |
| Memoria insuficiente en llama.cpp | Bajar `LLAMACPP_CTX`, activar `LLAMACPP_CPU_MOE` o usar una cuantización menor |
| El modelo local no usa herramientas o se corta | Subir el contexto a 32768 o usar un modelo mayor |
| No se puede clonar un repositorio | Si es privado: opción 7 (Conectar GitHub). Si no es de GitHub: añadir su dominio a `FIREWALL_ALLOW` |
| Un proyecto no enciende (`unhealthy`) | Ver el motivo con `docker logs entorno-ia-<proyecto>-workspace-1` |
| Una herramienta no conecta (`Connection refused`, `EHOSTUNREACH`) | El cortafuegos bloquea ese destino: añadirlo a `FIREWALL_ALLOW` |
| OpenCode no conecta con un proveedor | Añadir el dominio de su API a `FIREWALL_ALLOW` |
| VS Code no termina de abrir el proyecto | Añadir a `FIREWALL_ALLOW` el dominio que aparezca en el registro de *Dev Containers* |
| VS Code se abre como `root` o fuera de `/workspace` | Cerrar VS Code y volver a usar la opción 6 del menú |
| La construcción de la imagen falla | Comprobar la conexión y ejecutar `docker compose build --no-cache workspace` |
