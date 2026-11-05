# SQL Server 2022 with Full-Text Search (SPEC §22, F16). The official image has no full-text component, so this adds
# the `mssql-server-fts` package from Microsoft's apt repository (it brings the matching `mssql-server` package along).
# Used by docker-compose.yml (host port 14333) and by the integration tests (Testcontainers builds it from this folder).
# Without it the API still searches, with its LIKE fallback (docs/api/contract-v1.md, "Search").
FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl ca-certificates gnupg; \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-mssql.gpg; \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-mssql.gpg] https://packages.microsoft.com/ubuntu/22.04/mssql-server-2022 jammy main" \
        > /etc/apt/sources.list.d/mssql-server-2022.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends mssql-server-fts; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

USER mssql

CMD ["/opt/mssql/bin/sqlservr"]
