# Entorno IA

Entorno de desarrollo aislado en Docker con **Claude Code**, **OpenCode** y **Hermes Agent**, conectables a Claude o a un modelo local.

```
Windows
├─ LM Studio ── GPU ── :1234 ◄──────────┐
└─ Docker Desktop                       │
   ├─ workspace ────────────────────────┼──► api.anthropic.com
   │   Claude Code · OpenCode · git · gh · Node 22
   ├─ hermes ───────────────────────────┤   (opcional)
   └─ llamacpp ── GPU ── :8080 ◄────────┘   (opcional)
```

| | Suscripción Claude | API Anthropic | Modelo local |
|---|---|---|---|
| **Claude Code** | 1 | 2 | 3 |
| **OpenCode** | — | 5 | 4 |
| **Hermes Agent** | Solo Max con créditos extra | ✓ | ✓ (contexto ≥ 65536) |

## Requisitos

- Windows 10 22H2 o Windows 11, con la virtualización activada
- WSL2 (`wsl --install`)
- Docker Desktop con el motor WSL2
- Driver NVIDIA actualizado
- Modelo local, según el modo:
  - **LM Studio** 0.4.1 o superior
  - **llama.cpp**: GPU visible en Docker (`docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi`)

## Modelos recomendados

| Hardware | Modelo | `LLAMACPP_HF_REPO` |
|---|---|---|
| GPU 6–8 GB · 16 GB RAM | Qwen3.5-9B Q4_K_M | `unsloth/Qwen3.5-9B-GGUF:Q4_K_M` |
| GPU 8–16 GB · 32 GB RAM | Qwen3.6-35B-A3B Q4_K_M (expertos MoE en la CPU) | `unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_M` + `LLAMACPP_CPU_MOE=true` |
| GPU 24 GB o más | Qwen3.6-27B Q4_K_M | `unsloth/Qwen3.6-27B-GGUF:Q4_K_M` |

Contexto recomendado: 32768 (65536 para Hermes Agent).

## Instalación

```powershell
# Modelo local en LM Studio
powershell -ExecutionPolicy Bypass -File .\iniciar.ps1

# Modelo local en llama.cpp
powershell -ExecutionPolicy Bypass -File .\iniciar.ps1 -LlamaCpp
```

**LM Studio:** carga el modelo con contexto 32768 y GPU offload al máximo, y arranca el servidor en *Developer → Start Server*.

**llama.cpp:** el modelo se descarga en el primer arranque (`docker compose logs -f llamacpp`).

## Uso

```powershell
docker compose exec workspace ia        # menú
docker compose exec workspace ia 1      # opción directa
docker compose exec workspace bash      # terminal
```

Dentro del contenedor:

```bash
gh auth login
cd /workspace && gh repo clone <usuario>/<repo>
cd <repo> && ia
```

- **Editor:** VS Code → *Dev Containers: Attach to Running Container* → `entorno-ia-workspace-1`.
- **Servidores de desarrollo:** escuchar en `0.0.0.0` y abrir `http://localhost:<puerto>` (3000, 5173, 8080).

## Hermes Agent

```powershell
docker compose --profile hermes run --rm hermes setup    # primera vez: proveedor y modelo
docker compose --profile hermes run --rm hermes          # chat
```

Comparte `/workspace` con el contenedor de trabajo. URL del modelo local en `setup` → *Custom endpoint*:

| Modo | Base URL |
|---|---|
| LM Studio | `http://host.docker.internal:1234/v1` |
| llama.cpp | `http://llamacpp:8080/v1` |

## Configuración

`.env`:

| Variable | Descripción |
|---|---|
| `LOCAL_URL` | Servidor del modelo local (lo fija `iniciar.ps1`) |
| `LOCAL_MODEL` | Id del modelo; vacío = el primero disponible |
| `LLAMACPP_HF_REPO` | Modelo GGUF de Hugging Face (`usuario/repo:cuantización`) |
| `LLAMACPP_CTX` | Tamaño de contexto |
| `LLAMACPP_CPU_MOE` | `true` para dejar los expertos MoE en la RAM |
| `ANTHROPIC_API_KEY` | Clave de API (opciones 2 y 5) |
| `CLAUDE_MODEL` | Modelo de Claude en OpenCode |
| `GIT_USER_NAME`, `GIT_USER_EMAIL` | Identidad de git |

Aplicar cambios: `docker compose up -d` (añadir `--profile llamacpp` si se usa llama.cpp).

## Mantenimiento

| Tarea | Comando |
|---|---|
| Actualizar Claude Code y OpenCode | `docker compose build --pull && docker compose up -d` |
| Actualizar llama.cpp y Hermes Agent | `docker compose --profile llamacpp --profile hermes pull` |
| Borrar todo (sesiones, proyectos y modelos) | `docker compose --profile llamacpp --profile hermes down -v` |

## Solución de problemas

| Problema | Solución |
|---|---|
| `failed to connect to the docker API` | Abrir Docker Desktop y esperar a *Engine running* |
| No hay servidor de modelos (LM Studio) | Arrancar el servidor; si persiste, activar *Serve on Local Network* |
| No hay servidor de modelos (llama.cpp) | El modelo aún se está descargando: `docker compose logs -f llamacpp` |
| `could not select device driver "nvidia"` | Actualizar el driver NVIDIA y Docker Desktop |
| Memoria insuficiente | Bajar `LLAMACPP_CTX`, activar `LLAMACPP_CPU_MOE` o usar una cuantización menor |
| Hermes no usa herramientas con el modelo local | Contexto ≥ 65536 (`LLAMACPP_CTX=65536` o en LM Studio) |
| `entrypoint.sh: no such file` | Finales de línea CRLF: `docker compose build --no-cache` |

## Licencia

[MIT](LICENSE). Proyecto personal, sin garantías.
