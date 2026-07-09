# mcp-sandbox-setup

Docker Compose stack that builds two containers on a remote host: an nginx reverse proxy (open to internet traffic) and a remote MCP server (only nginx can reach it). Ideal for blast radius containment when testing LLMs and sketchy code.

*Intended for use as a disposable sandbox for Cybersecurity purposes. Prompt injection only impacts contents inside the container, not on the host.*

```
System:  {user} <--> mcp-client-console <--> internet <--> {host:80} <--> nginx <--> mcp-server-remote <--> tools
Stack:   docker-compose.yml <--> Dockerfile <--> config/config.toml + nginx/default.conf
```

## Repo Layout


| File                 | Purpose                                                              |
| -------------------- | -------------------------------------------------------------------- |
| `docker-compose.yml` | Declares both containers, the network between them, and the mounts   |
| `Dockerfile`         | Builds the MCP server image (python base + pip install)              |
| `nginx/default.conf` | nginx config, proxies host port 80 to the server container           |
| `config/config.toml` | Server config, mounted into the container (edit this before first run) |

## User Guide | Installation

Requires Docker Engine and the Docker Compose plugin on the host.

```bash
git clone https://github.com/geomux/mcp-sandbox-setup.git
cd mcp-sandbox-setup
# edit config/config.toml first (see Configuration below)
docker compose up -d --build
```

## User Guide | Configuration

The server config lives in this repo at `config/config.toml` and is bind mounted into the container. Edit it on the host, no need to enter the container:

```toml
[server]
name = "Sandbox_1"  # Label for this sandbox
host = "0.0.0.0"    # Bind all container interfaces so nginx can reach it. Do NOT use 127.0.0.1 here.
port = 9000         # Port nginx proxies to
path = "/mcp"       # Leave this alone. /mcp is default for dependencies.
```

Generate a token with `openssl rand -hex 32` and paste it into `[auth]`, same drill as the server repo. Restart the stack after any config change:

```bash
docker compose restart mcp-server
```

## User Guide | Operation

| Command                                | What it does                                  |
| -------------------------------------- | --------------------------------------------- |
| `docker compose up -d --build`         | Build images and start both containers        |
| `docker compose logs -f mcp-server`    | Tail the MCP server logs                      |
| `docker compose exec mcp-server bash`  | Shell into the server container (no SSH here) |
| `docker compose down`                  | Stop and remove the stack                     |

Only nginx publishes a port to the host. The MCP server container has no published ports, it is only accessible via the internal Docker network. If the sandbox gets wrecked, `docker compose down && docker compose up -d --build` gives you a clean slate again.

## Related / Required Repos

- [mcp-server-remote](https://github.com/geomux/mcp-server-remote)
- [mcp-client-console](https://github.com/geomux/mcp-client-console)

## Project Status

- [x] Create sandbox repo
- [ ] Write Dockerfile for mcp-server-remote
- [ ] Write nginx reverse proxy config
- [ ] Write docker-compose.yml wiring both containers
- [ ] Connect from mcp-client-console through nginx end to end
- [ ] Harden (non-root container user, TLS on nginx)
- [ ] Call this repo from Terraform
