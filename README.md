# claude-code-local-llm-docker

Contenedor Docker para Windows con Claude Code y OpenCode, conectables a la suscripción de Claude, a la API de Anthropic o a un modelo local servido por LM Studio o llama.cpp.

```
Windows
├─ LM Studio (opcional) ── GPU ── :1234 ◄─────────────┐
│                                                     │
└─ Docker Desktop (WSL2)                              │
   │                                                  │
   ├─ workspace ──────────────────────────────────────┤
   │   Claude Code · OpenCode · git · gh · Node 22    │
   │   menú: ia                                       │
   │   volúmenes: home, workspace                     ├──► api.anthropic.com
   │                                                  │
   └─ llamacpp (opcional) ── GPU ── :8080 ◄───────────┘
       volumen: models
```
