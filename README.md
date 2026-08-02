# mcp-sandbox-setup

Docker Compose stack that builds two containers on a remote host: an nginx reverse proxy (open to internet traffic) and a remote MCP server (only nginx can reach it). Ideal for blast radius containment when testing LLMs and sketchy code.

*Intended for use as a disposable sandbox for Cybersecurity purposes. Prompt injection only impacts contents inside the container, not on the host.*

```
System:  {user} <--> mcp-client-console <--> internet <--> {host:443} <--> nginx <--> mcp-server-remote <--> tools
Stack:   docker-compose.yml <--> Dockerfile <--> config/config.toml + nginx/mcp-tls.conf
```

## Repo Layout

| File                 | Purpose                                                              |
| -------------------- | -------------------------------------------------------------------- |
| `docker-compose.yml` | Declares both containers, the network between them, and the mounts   |
| `Dockerfile`         | Builds the MCP server image (Ubuntu base + pipx install)              |
| `nginx/mcp-tls.conf` | nginx config, proxies host port 443 to the server container           |
| `nginx/gen-cert.sh` | bash shell script to generate TLS certificate            |
| `config/config.toml` | Server config, mounted into the container (edit this before first run) |


## User Guide | Installation

Requires Docker Engine and the Docker Compose plugin on the host.

*MUST FOLLOW DIRECTIONS BELOW TO PROPERLY SETUP THE SANDBOX*

> [!NOTE]
> This repo stack allows HTTPS only, and you will need the .crt generated in installation below unless you reach the sandbox containers through a tunnel.

```bash
git clone https://github.com/geomux/mcp-sandbox-setup.git
cd mcp-sandbox-setup/config && cp config.toml.example config.toml && openssl rand -hex 32
```
*COPY FRESHLY GENERATED TOKEN TO CLIPBOARD, PASTE INTO [auth] BELOW*
**Populate config file as desired while inside the file during next step**
```bash
nano config.toml && cd ..
./nginx/gen-cert.sh
sudo docker compose up -d --build
```

## User Guide | Prerequisites (any OS)

Works on Linux, macOS, and Windows... the actual sandbox containers are Linux.

| Host OS | Install Docker |
| ------- | -------------- |
| Linux   | `sudo curl -fsSL https://get.docker.com \| sh` |
| macOS   | [Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/) 
| Windows | [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/)
**On Windows, Install Docker commands to be run through WSL**


## User Guide | Configuration

The server config lives in this repo at `config/config.toml` and is bind mounted into the container. Edit it on the host, no need to enter the container:

```toml
[server]
name = "Sandbox_1"  # Label for this sandbox
host = "0.0.0.0"    # Bind all container interfaces so nginx can reach it. Do NOT use 127.0.0.1 here.
```

Generate a token with `openssl rand -hex 32` and paste it into `[auth]`, same drill as the server repo. Restart the stack after any config change:

```bash
sudo docker compose restart mcp-server-remote
```

## User Guide | Operation

| Command                                       | What it does                                  |
| --------------------------------------------- | --------------------------------------------- |
| `sudo docker compose up -d --build`                | Build images and start both containers        |
| `sudo docker compose logs -f mcp-server-remote`    | Tail the MCP server logs                      |
| `sudo docker compose exec mcp-server-remote bash`         | Shell into the server container (no SSH needed) |
| `sudo docker compose down`                         | Stop and remove the stack                     |

**Clean Up Operations (general docker clean-house stuff)**
| Command                                       | What it does                                  |
| --------------------------------------------- | --------------------------------------------- |
| `sudo docker image prune -f`                | Delete untagged "<None>" images from past builds        |
| `sudo docker builder prune -f`                | Delete cache from past builds        |


Only nginx publishes a port to the host. The MCP server container has no published ports, it is only accessible via the internal Docker network. If the sandbox gets wrecked by bad code or prompt injection, `sudo docker compose down && sudo docker compose up -d --build` creates a clean slate again.


## User Guide | Connecting a Client (mcp-client-console)

Copy to client machine the `nginx/tls/mcp.crt` (NEVER `mcp.key`) you generated during Installation.

```toml
[[server]]
name = "Sandbox_1"
url = "https://your-url-here/mcp"
token = "pasted-here-generated-during-installation"
ca_cert = "/path/to/server_name/mcp.crt" 
```
It is recommended to put the mcp.crt in a folder with [[server]] name to properly organize the certificates when managing multiple remote sandbox/MCP servers.
EXAMPLE: 
```toml
ca_cert = "/home/self/env/Sandbox_1/mcp.crt" 
```
OR
```toml
ca_cert = 'C:Users/self/certs/Sandbox_1\mcp.crt'
```

## User Guide | Optional: Cloudflare Tunnel

Reach the sandbox from the outside without opening any ports or distributing the `.crt`.

Requires [cloudflared] installed.

Use the url the following commands as your [url] in the client Config to reach this sandbox/MCP server.

```bash
cloudflared tunnel --url https://localhost:443 --no-tls-verify
```


## Related / Required Repos

- [mcp-server-remote](https://github.com/geomux/mcp-server-remote)
- [mcp-client-console](https://github.com/geomux/mcp-client-console)


## Project Status

- [x] Create sandbox repo
- [x] Write Dockerfile for mcp-server-remote
- [x] Write nginx reverse proxy config
- [x] Write docker-compose.yml wiring both containers
- [x] Connect from mcp-client-console through nginx end to end (over the internet, into the container)
- [x] Clean it up (non-root container user, TLS on nginx)
- [ ] Call this repo from a Terraform recipe
