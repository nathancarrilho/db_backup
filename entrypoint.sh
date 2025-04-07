#!/bin/bash
set -e

# Verificar se o arquivo .env existe, caso contrário copiar o exemplo
if [ ! -f /app/.env ]; then
    echo "Arquivo .env não encontrado. Utilizando .env.example..."
    cp /app/.env.example /app/.env
fi

# Gerar chave de encriptação caso não exista
if ! grep -q "ENCRYPTION_KEY" /app/.env; then
    echo "Gerando chave de encriptação..."
    RANDOM_KEY=$(openssl rand -base64 32)
    echo "ENCRYPTION_KEY=${RANDOM_KEY}" >> /app/.env
    echo "Chave de encriptação gerada e salva no arquivo .env"
fi

# Verifica se a execução é manual ou agendada
if [ "$1" = "backup" ]; then
    echo "Executando backup manual..."
    /app/backup.sh
    exit 0
fi

# Configurar cron
echo "Configurando agendamento de backups..."
echo "0 3 * * * /app/backup.sh > /proc/1/fd/1 2>/proc/1/fd/2" > /etc/crontabs/root
echo "0 14 * * * /app/backup.sh > /proc/1/fd/1 2>/proc/1/fd/2" >> /etc/crontabs/root

echo "Backup agendado para 03:00 AM e 14:00 PM (UTC) todos os dias."
echo "Iniciando serviço cron em primeiro plano..."

# Iniciar cron em primeiro plano
crond -f -l 8