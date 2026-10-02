# Entorno IA

Entorno de desarrollo aislado en Docker con Claude Code y OpenCode, conectables a Claude o a un modelo local (LM Studio o llama.cpp).

| | Suscripción Claude | API Anthropic | Modelo local |
|---|---|---|---|
| Claude Code | ✓ | ✓ | ✓ |
| OpenCode | — | ✓ | ✓ |

## Requisitos

- Windows 10/11 con WSL2
- Docker Desktop
- GPU NVIDIA (opcional)
- LM Studio 0.4.1+ (opcional)

## Instalación

```powershell
.\iniciar.ps1              # modelo local en LM Studio
.\iniciar.ps1 -LlamaCpp    # modelo local en llama.cpp
```

## Uso

```powershell
docker compose exec workspace ia
```

## Modelos

| GPU | RAM | `LLAMACPP_HF_REPO` |
|---|---|---|
| 6–8 GB | 16 GB | `unsloth/Qwen3.5-9B-GGUF:Q4_K_M` |
| 8–16 GB | 32 GB | `unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_M` + `LLAMACPP_CPU_MOE=true` |
| 24 GB+ | — | `unsloth/Qwen3.6-27B-GGUF:Q4_K_M` |

Contexto recomendado: 32768.

## Configuración

| Variable | |
|---|---|
| `LOCAL_URL` | Servidor del modelo local |
| `LOCAL_MODEL` | Modelo local (vacío = automático) |
| `LLAMACPP_HF_REPO` | Modelo GGUF de Hugging Face |
| `LLAMACPP_CTX` | Contexto |
| `LLAMACPP_CPU_MOE` | Expertos MoE en la RAM |
| `ANTHROPIC_API_KEY` | Clave de API |
| `CLAUDE_MODEL` | Modelo de Claude en OpenCode |
| `GIT_USER_NAME`, `GIT_USER_EMAIL` | Identidad de git |

## Licencia

[MIT](LICENSE)
