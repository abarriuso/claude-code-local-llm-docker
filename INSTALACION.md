# Instalación

Guía desde cero en Windows 10/11. Los comandos se ejecutan en **PowerShell como administrador** salvo que se indique otra cosa.

1. [Virtualización](#1-virtualización)
2. [WSL2](#2-wsl2)
3. [Docker Desktop](#3-docker-desktop)
4. [Git](#4-git)
5. [GPU NVIDIA (opcional)](#5-gpu-nvidia-opcional)
6. [LM Studio (opcional)](#6-lm-studio-opcional)
7. [Descargar el repositorio](#7-descargar-el-repositorio)
8. [Primer arranque](#8-primer-arranque)
9. [Comprobación](#9-comprobación)

## 1. Virtualización

Administrador de tareas → *Rendimiento* → *CPU* → **Virtualización: Habilitada**.

Si aparece *Deshabilitada*, activarla en la BIOS/UEFI (*Intel VT-x* / *Intel Virtualization Technology* o *AMD-V* / *SVM Mode*).

## 2. WSL2

```powershell
wsl --install
```

Reiniciar el equipo. Comprobar:

```powershell
wsl --status
```

Debe indicar la versión predeterminada **2**. Si WSL ya estaba instalado:

```powershell
wsl --update
wsl --set-default-version 2
```

## 3. Docker Desktop

```powershell
winget install -e --id Docker.DockerDesktop
```

O descargarlo de https://www.docker.com/products/docker-desktop/.

1. Abrir Docker Desktop y aceptar los términos.
2. *Settings → General* → **Use the WSL 2 based engine** activado.
3. Esperar a **Engine running** (abajo a la izquierda).

Si aparece *access denied* al usar `docker`, añadir el usuario al grupo y cerrar sesión en Windows:

```powershell
net localgroup docker-users "$env:USERNAME" /add
```

## 4. Git

```powershell
winget install -e --id Git.Git
```

O descargarlo de https://git-scm.com/download/win y aceptar las opciones por defecto.

Cerrar y volver a abrir PowerShell. Comprobar con `git --version`.

## 5. GPU NVIDIA (opcional)

Solo para usar un modelo local.

1. Instalar el driver más reciente desde https://www.nvidia.com/Download/index.aspx o con la aplicación NVIDIA.
2. Reiniciar Docker Desktop.
3. Comprobar que Docker ve la GPU (PowerShell normal):

```powershell
docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
```

Debe mostrar una tabla con el nombre de la GPU.

## 6. LM Studio (opcional)

Solo si el modelo local se sirve con LM Studio (alternativa: llama.cpp en Docker, sin instalar nada más).

```powershell
winget install -e --id ElementLabs.LMStudio
```

O descargarlo de https://lmstudio.ai. Se necesita la versión 0.4.1 o superior.

1. *Discover* → descargar un modelo (ver *Modelos recomendados* en el [manual](MANUAL.md#modelos-recomendados)).
2. Cargar el modelo con contexto **32768** y *GPU offload* al máximo.
3. *Developer* → **Start Server** (puerto 1234).

## 7. Descargar el repositorio

PowerShell normal:

```powershell
cd $HOME\Documents
git clone https://github.com/abarriuso/claude-code-local-llm-docker.git
cd claude-code-local-llm-docker
```

## 8. Primer arranque

Con Docker Desktop en *Engine running*:

```powershell
.\iniciar.cmd              # LM Studio o sin modelo local
.\iniciar.cmd -LlamaCpp    # llama.cpp
```

La primera vez construye la imagen (unos minutos). Al terminar se abre el menú.

Opcional: editar `.env` para añadir `ANTHROPIC_API_KEY`, `GIT_USER_NAME` y `GIT_USER_EMAIL`, y volver a ejecutar `iniciar.cmd`.

## 9. Comprobación

En el menú:

1. La cabecera muestra el modelo local (o *sin servidor* si no se usa).
2. Opción **1** → Claude Code muestra una URL de inicio de sesión. Abrirla, iniciar sesión y pegar el código.
3. Escribir `/exit` para salir.

Si todo funciona, continuar con el [manual de uso](MANUAL.md).
