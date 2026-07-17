# Conexión a los MCPs de LTEM y CONAPESCA

**No hacen falta scripts.** Los MCP son servidores HTTP; el cliente (Claude Code
/ Claude Desktop) se conecta leyendo esta configuración. Basta con pegar el
bloque en el archivo de configuración MCP y reiniciar el cliente.

> El token real vive en `docs/mcp_connection.md` (gitignored). Aquí va con
> placeholder para no exponer credenciales en el repo.

## Configuración (pegar en el `.mcp.json` del cliente)

```json
{
  "mcpServers": {
    "ltem": {
      "type": "http",
      "url": "http://<MCP_SERVER>/ltem/",
      "headers": {
        "Authorization": "Basic <BASIC_AUTH_TOKEN>"
      }
    },
    "conapesca": {
      "type": "http",
      "url": "http://<MCP_SERVER>/conapesca/",
      "headers": {
        "Authorization": "Basic <BASIC_AUTH_TOKEN>"
      }
    }
  }
}
```

**Dónde pegarlo:**
- Ámbito usuario (global): `~/.claude/mcp.json`
- Ámbito proyecto: `.mcp.json` en la raíz del proyecto

`<BASIC_AUTH_TOKEN>` = `base64("usuario:contraseña")`. Pídelo al equipo. Ambos
MCP usan el mismo Basic Auth.
