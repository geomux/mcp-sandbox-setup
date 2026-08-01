# Dockerfile
# Create image for mcp server on linux Ubuntu OS

FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    python3 pipx \
    && rm -rf /var/lib/apt/lists/*

ARG MCP_SERVER_VERSION=0.3.5
RUN pipx install "mcp-server-remote==${MCP_SERVER_VERSION}"

ENV PATH="/root/.local/bin:$PATH"

EXPOSE 9000

CMD ["mcp-server-remote"]
