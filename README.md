# claude-code-local-llm-docker

Contenedor Docker para Windows con Claude Code (suscripción o API de Anthropic) y OpenCode (API de Anthropic o modelo local servido por LM Studio o llama.cpp).

```
Windows
├─ LM Studio (opcional) ── GPU ── :1234 ◄─────────────┐
│                                                     │
└─ Docker Desktop (WSL2)                              │
   │                                                  │
   ├─ workspace ──────────────────────────────────────┤
   │   Claude Code · OpenCode · git · gh · Node 22    │
   │   menú: ia · usuario sin privilegios             │
   │   volúmenes: home, workspace                     │
   │   cortafuegos de salida ─────────────────────────┼──► Anthropic, npm, GitHub
   │                                                  │
   └─ llamacpp (opcional) ── GPU ── :8080 ◄───────────┘
       volumen: models
```

[Instalación](INSTALACION.md) · [Manual de uso](MANUAL.md)
