FROM alpine:3.18

# Instalar dependências
RUN apk add --no-cache \
    bash \
    postgresql-client \
    openssl \
    tzdata \
    coreutils \
    findutils \
    tar \
    curl

# Configurar timezone para UTC
RUN cp /usr/share/zoneinfo/UTC /etc/localtime && \
    echo "UTC" > /etc/timezone

# Criar diretórios necessários
RUN mkdir -p /app /backup /mnt/backups

# Copiar arquivos
COPY backup.sh /app/
COPY entrypoint.sh /app/
COPY .env.example /app/.env.example

# Definir permissões
RUN chmod +x /app/backup.sh /app/entrypoint.sh

WORKDIR /app

# Definir entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]