#!/bin/bash
set -e

echo "Configurando ambiente para backups do PostgreSQL BICA..."

# Criar diretórios necessários
mkdir -p config backup-temp init-db /mnt/backups

# Verificar se .env já existe, caso contrário copiar o exemplo
if [ ! -f config/.env ]; then
    echo "Criando arquivo de configuração .env..."
    cp .env.example config/.env
    
    # Gerar chave de encriptação
    RANDOM_KEY=$(openssl rand -base64 32)
    echo "ENCRYPTION_KEY=${RANDOM_KEY}" >> config/.env
    echo "Chave de encriptação gerada e adicionada ao arquivo .env"
fi

# Configurar permissões
chmod +x backup.sh entrypoint.sh setup.sh test-backup.sh

echo "Ambiente configurado com sucesso!"
echo "Para iniciar os serviços, execute: docker-compose up -d"
echo "Para testar o backup manualmente, execute: ./test-backup.sh"