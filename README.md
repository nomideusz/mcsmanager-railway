# Deploy and Host MCSManager on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/mcsmanager?referralCode=sLjDXb&utm_medium=integration&utm_source=button&utm_campaign=mcsmanager)

[MCSManager](https://mcsmanager.com/) is a popular open-source web panel for game servers, used by many Minecraft server owners, especially in China. This template runs the panel and its daemon in one Railway service. You install Paper, Purpur, Fabric, Forge or NeoForge from its app market, then run them from the browser: live console, file manager, scheduled tasks, and user accounts with their own permissions.

## About Hosting MCSManager

It's one service, a Railway volume, and a TCP proxy for players.

- **Locked down from the start.** Normally, whoever opens a new MCSManager panel first gets to create the admin. Here, the `admin` account is created during the first boot with the password from your variables, before the panel is reachable.
- **Panel and daemon together.** The daemon that runs your game servers lives in the same container and is already connected as the node "Railway". The console and file uploads go through your Railway domain.
- **Java 25 and Java 21 built in.** Java 25 runs Minecraft 26.x and 1.21.x. Older modpacks can get another Java from the panel's Java Manager.
- **Survives redeploys.** Instances, worlds and panel settings live on the volume. On a redeploy the daemon stops every server cleanly so worlds are saved.

## Common Use Cases

- A private Minecraft survival server for friends, with plugins (Paper/Purpur) or mods (Fabric/Forge/NeoForge)
- Several Minecraft servers managed from one panel, each with its own port
- Giving friends or staff their own panel accounts that can only see their own servers

## Dependencies for MCSManager Hosting

- Railway's Hobby plan or above: a Minecraft server needs about 2 GB of memory

### Deployment Dependencies

- [MCSManager documentation](https://docs.mcsmanager.com/)
- [MCSManager on GitHub](https://github.com/MCSManager/MCSManager)
- [Template source on GitHub](https://github.com/nomideusz/mcsmanager-railway)

### Implementation Details

**Sign in.** Open the service's Railway domain and sign in as `admin` with the `MCSM_ADMIN_PASSWORD` value from the Variables tab. You can change the password later under your user profile.

**Create a server.** Go to **Market**, pick a Minecraft template (for example "[PaperMC] Minecraft 26.1.2"), choose the normal (non-Docker) install, then press **Start**. On its first start the server stops and asks you to accept [Mojang's EULA](https://aka.ms/MinecraftEULA). To accept it, open **File Management**, set `eula=true` in `eula.txt`, and start the server again.

**Memory.** The market templates start Java with `-Xms4096M -Xmx4096M`. If you want a smaller server, lower these numbers under **Instance Settings → Startup Command** before you start it. Railway bills the memory actually used, which is about 2 GB for a fresh world.

**Join.** Players connect to the address under Settings → Networking → TCP Proxy (something like `xyz.proxy.rlwy.net:12345`). It's also in the deploy logs, on the line starting "players join at". The proxy points at port 25565, which is the port the first server uses by default.

**Turn on Auto Start.** Without it, a server stays stopped after a redeploy or restart until you press Start. Turn it on in each server's **Event Tasks**.

**More servers.** Give each extra server its own `server-port` in `server.properties`, and add a TCP proxy for that port (Settings → Networking).

**Limits on Railway.** Railway gives no Docker access inside a service and its TCP proxy can't carry UDP. So the market's Docker/Steam templates (Palworld, Rust, Terraria, ...) and Minecraft Bedrock won't work here. Java Edition servers are fine.

**Custom domain.** The browser reaches the daemon through the Railway domain. If you add your own domain, add it to a `MCSM_EXTRA_DOMAINS` variable (comma-separated, e.g. `mc.example.com`) and redeploy, so the console and file manager work there too.

**Backups.** Everything lives on one volume (5 GB to start; you can grow it in its settings). For a copy off Railway, download world folders now and then from File Management, or use Railway's volume backups.

### 中文说明

用 Railway 域名打开面板，用户名 `admin`，密码是变量里的 `MCSM_ADMIN_PASSWORD`。部署时把 `MCSM_LANGUAGE` 设为 `zh_cn` 即可使用中文界面（之后也可在设置里修改）。在“应用市场”选择 Minecraft 模板（选非 Docker 方式安装），首次启动后在文件管理里把 `eula.txt` 改为 `eula=true` 再启动。玩家通过 Settings → Networking 中的 TCP Proxy 地址连接。建议在“事件任务”里开启自动启动，否则重新部署后服务器不会自动开启。Railway 不支持 Docker 和 UDP，所以 Docker/Steam 模板和基岩版无法使用。

## Why Deploy MCSManager on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying MCSManager on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
