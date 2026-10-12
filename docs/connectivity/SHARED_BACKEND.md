# Shared backend design

The public Savour frontend now calls a Java/Oracle backend through a temporary Cloudflare Quick Tunnel, configured in the public repository's backend-config.js. Java permits cross-origin requests from https://aaron-rby.github.io. The browser polls every five seconds while no form is being edited and retries an offline backend; writes remain disabled while offline. Earlier localStorage orders are not imported.

Start the local server with the commands in connectivity/README.md, then run the official cloudflared executable:

```powershell
cloudflared tunnel --url http://127.0.0.1:8788 --http-host-header 127.0.0.1:8788 --no-autoupdate --protocol http2
```

Copy the generated HTTPS URL into window.SAVOUR_API_BASE in the public repository's backend-config.js, commit and push. Keep Oracle, Java and cloudflared running; a new Quick Tunnel has a new URL. Download the tool from https://developers.cloudflare.com/tunnel/downloads/. There is no login, so anyone using the site can select Admin. Use fictional project data only.

A shared backend stores orders on a server instead of in each browser's localStorage. Customer, driver and admin views all read the same records.

The public frontend calls a configured HTTPS API. The server validates operations and commits order changes to its database. Other browsers refresh the state periodically to see new orders and status changes.

This version intentionally has no login. Role selection is a demonstration filter, not access control. Use fictional data. A delivery partner who orders food must have a CUSTOMER role as well; their ordering identity and delivery assignment are separate references.

The original local Oracle project remains available. Hosting choices are a temporary HTTPS tunnel to a running local Java/Oracle server, or a separately hosted cloud backend/database.
