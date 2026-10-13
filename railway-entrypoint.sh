#!/bin/bash
# Railway entrypoint for MCSManager: panel + daemon in one container, state on the one
# volume, Caddy on $PORT, and the admin account and local node set up on first boot.
set -euo pipefail

mkdir -p /data/web/SystemConfig /data/web/RemoteServiceConfig /data/uploads /data/daemon/Config

# First boot: the daemon only listens inside the container, under /daemon, with a key we know.
if [ ! -e /data/daemon/Config/global.json ]; then
  node -e 'const k=require("crypto").randomBytes(24).toString("hex");
    console.log(JSON.stringify({ip:"127.0.0.1", port:24444, prefix:"/daemon", key:k}))' \
    > /data/daemon/Config/global.json
fi
# Panel: internal only, behind Caddy. Language is first-boot only; change it in Settings.
if [ ! -e /data/web/SystemConfig/config.json ]; then
  MCSM_LANGUAGE="${MCSM_LANGUAGE:-en_us}" node -e 'console.log(JSON.stringify({httpIp:"127.0.0.1",
    httpPort:23333, reverseProxyMode:true, reverseProxyHeader:"X-Real-IP",
    language:process.env.MCSM_LANGUAGE}))' > /data/web/SystemConfig/config.json
fi

# The local node. The panel reaches it on 127.0.0.1:24444; the browser can't, so a remote
# mapping sends it to wss://<railway domain>/daemon. Refreshed every boot: the domain can change.
node -e '
const fs = require("fs");
const f = "/data/web/RemoteServiceConfig/railway-local-node.json";
const key = JSON.parse(fs.readFileSync("/data/daemon/Config/global.json")).key;
const node = fs.existsSync(f) ? JSON.parse(fs.readFileSync(f)) : { remarks: "Railway" };
Object.assign(node, { ip: "127.0.0.1", port: 24444, prefix: "/daemon", apiKey: key });
const domains = [process.env.RAILWAY_PUBLIC_DOMAIN,
  ...(process.env.MCSM_EXTRA_DOMAINS || "").split(",")].map((d) => (d || "").trim()).filter(Boolean);
node.remoteMappings = domains.map((d) => {
  const [ip, port = "443"] = d.split(":");
  return { from: { ip, port: +port, prefix: "" }, to: { ip, port: +port, prefix: "/daemon" } };
});
fs.writeFileSync(f, JSON.stringify(node, null, 2));
'

if [ -n "${RAILWAY_TCP_PROXY_DOMAIN:-}" ]; then
  echo "railway: players join at $RAILWAY_TCP_PROXY_DOMAIN:$RAILWAY_TCP_PROXY_PORT (server port 25565)"
fi

# The daemon stops every running instance cleanly on SIGTERM; pass it on and wait.
# RAILWAY_DEPLOYMENT_DRAINING_SECONDS gives it the time.
trap 'kill $(jobs -p) 2>/dev/null; wait; exit 0' TERM INT

(cd /opt/mcsmanager/daemon && exec node app.js) &
daemon_pid=$!
(cd /opt/mcsmanager/web && exec node app.js) &
panel_pid=$!

until curl -fs -o /dev/null http://127.0.0.1:23333/; do
  kill -0 "$panel_pid" 2>/dev/null || { echo "panel exited during startup"; exit 1; }
  sleep 1
done

# First boot: the panel lets whoever opens it first create the admin. Do it here,
# before Caddy makes the panel reachable, with the password from the Railway variable.
if [ -z "$(ls -A /data/web/User 2>/dev/null)" ]; then
  out=$(curl -s -X POST http://127.0.0.1:23333/api/auth/install -H 'Content-Type: application/json' \
    -H 'X-Requested-With: XMLHttpRequest' \
    -d "$(node -e 'console.log(JSON.stringify({username:"admin", password:process.env.MCSM_ADMIN_PASSWORD||""}))')")
  echo "$out" | grep -q '"data":true' || { echo "admin setup failed (MCSM_ADMIN_PASSWORD needs 9-36 chars with a-z, A-Z and 0-9): $out"; exit 1; }
  echo "railway: created panel user admin"
fi

caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
caddy_pid=$!

# Any of the three exiting means the service is broken: exit so Railway restarts it.
wait -n "$daemon_pid" "$panel_pid" "$caddy_pid"
exit 1
