# claude-code-local-llm-docker

Agentes de IA (Claude Code y OpenCode) listos para usar en Windows. Cada proyecto va en su propio contenedor de Docker, aislado del resto del ordenador y protegido por un cortafuegos. Solo hace falta instalar Docker Desktop: todo lo demás viene dentro.

```
Windows
├─ iniciar.cmd ── menú: proyectos → Claude Code, OpenCode, terminal, VS Code
│
├─ LM Studio (opcional) ── GPU ── :1234 ◄────────────────────┐
│                                                            │
└─ Docker Desktop                                            │
   ├─ proyecto "web"     ── archivos propios · :3001 :5174   │
   ├─ proyecto "tienda"  ── archivos propios · :3002 :5175   │
   │    Claude Code · OpenCode · git · gh · Node 22 · Python │
   │    usuario sin privilegios · cortafuegos de salida ─────┼──► Anthropic, GitHub, npm, PyPI
   │                                                         │
   ├─ compartido: sesiones (Claude, OpenCode, GitHub) y modelos
   └─ llamacpp (opcional) ── GPU ── :8090 ◄──────────────────┘
```

## Empezar

1. Instala [Docker Desktop](https://www.docker.com/products/docker-desktop/) y ábrelo.
2. Descarga este repositorio (*Code → Download ZIP*) y extráelo.
3. Doble clic en **`iniciar.cmd`** → **N** (nuevo proyecto) → **1** (Claude Code).

Paso a paso, con los requisitos: [INSTALACION.md](INSTALACION.md).

## Documentación

- [Instalación](INSTALACION.md): requisitos y primeros pasos, sin comandos.
- [Manual de uso](MANUAL.md): menú, proyectos, configuración, modelo local y solución de problemas.
- [Cómo trabajar con agentes](GUIA-AGENTES.md): cómo sacarles partido sin sustos.

## Para quien mantiene el repositorio

- El CI publica la imagen en `ghcr.io/<usuario>/claude-code-local-llm-docker` en cada push a `main` y cada lunes (con las últimas versiones de Claude Code y OpenCode). La primera vez hay que hacer **pública** la imagen en GitHub (*Packages → Package settings → Change visibility*); mientras sea privada, `iniciar.cmd` la construye en el PC del usuario.
- Si cambias la imagen (`Dockerfile`, `scripts/`, `plantillas/`), sube `LABEL entorno-ia.version` en el `Dockerfile` y `$VersionImagen` en `iniciar.ps1`. El CI comprueba que coinciden.
