# Entorno de trabajo

Trabajas dentro de un contenedor Docker aislado, uno por proyecto. Ten en cuenta:

- **Archivos:** el proyecto está en `/workspace`. No tienes acceso al disco del ordenador del usuario ni a otros proyectos.
- **Permisos:** eres el usuario `node`, sin `sudo`. No puedes instalar paquetes del sistema con `apt`. Tienes git, gh, Node.js 22, npm, Python 3 (con `venv` y `pip`), ripgrep, jq y curl. Instala las dependencias dentro del proyecto (`npm install`, `python3 -m venv .venv`).
- **Red:** un cortafuegos solo deja salir hacia destinos permitidos (Anthropic, GitHub, npm, PyPI y algunos proveedores de modelos). Si una conexión falla con `Connection refused`, `EHOSTUNREACH` o se queda colgada, no insistas ni intentes saltarte el cortafuegos: dile al usuario qué dominio hace falta para que lo añada a `FIREWALL_ALLOW` en el archivo `.env`.
- **Servidores de desarrollo:** escucha en `0.0.0.0` (no en `localhost`) y usa los puertos 3000, 5173 u 8080. El usuario los abre desde su navegador; el menú del entorno le dice en qué dirección.
- **Git:** el código solo está a salvo cuando está subido a GitHub. Trabaja en una rama, haz commits pequeños con mensajes claros y no uses `push --force` ni reescribas el historial sin que te lo pidan.
- **El usuario puede estar empezando:** explica en español sencillo qué vas a hacer, por qué, y cómo puede comprobar que funciona.
