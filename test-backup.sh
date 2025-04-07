#!/bin/bash
set -e

echo "Executando teste de backup..."

# Verificar se os serviços estão em execução
if ! docker ps | grep -q "bica-backup"; then
    echo "O contêiner de backup não está em execução. Iniciando serviços..."
    docker-compose up -d
    sleep 5
fi

# Executar backup manual
echo "Executando backup manual..."
docker exec -it bica-backup /app/backup.sh

# Verificar se o backup foi criado
BACKUP_COUNT=$(find /mnt/backups -name "bica-backup-*.tar.gz.enc" | wc -l)

if [ $BACKUP_COUNT -gt 0 ]; then
    echo "Teste concluído com sucesso! Backup criado em /mnt/backups/"
    ls -la /mnt/backups/
else
    echo "Erro: Backup não encontrado!"
    exit 1
fi

# Testar restauração (opcional)
echo "Deseja testar a restauração do backup? (s/n)"
read resposta

if [ "$resposta" = "s" ]; then
    echo "Testando restauração do backup mais recente..."
    BACKUP_FILE=$(find /mnt/backups -name "bica-backup-*.tar.gz.enc" | sort -r | head -n 1)
    
    # Decriptar o arquivo de backup
    DECRYPTED_FILE="${BACKUP_FILE%.enc}"
    openssl enc -aes-256-cbc -d -in "$BACKUP_FILE" -out "$DECRYPTED_FILE" -k $(grep ENCRYPTION_KEY config/.env | cut -d '=' -f2)
    
    # Descompactar o arquivo
    BACKUP_DIR="${DECRYPTED_FILE%.tar.gz}"
    mkdir -p "$BACKUP_DIR"
    tar -xzf "$DECRYPTED_FILE" -C "$BACKUP_DIR"
    
    # Restaurar o backup para um banco de dados temporário
    docker exec -it bica-postgres psql -U postgres -c "CREATE DATABASE bica_restore;"
    
    BACKUP_PATH=$(find "$BACKUP_DIR" -type d -name "bica-backup-*")
    docker exec -it bica-postgres pg_restore -U postgres -d bica_restore "$BACKUP_PATH"
    
    # Verificar a restauração
    docker exec -it bica-postgres psql -U postgres -d bica_restore -c "SELECT COUNT(*) FROM users;"
    
    # Limpeza
    docker exec -it bica-postgres psql -U postgres -c "DROP DATABASE bica_restore;"
    rm -rf "$DECRYPTED_FILE" "$BACKUP_DIR"
    
    echo "Teste de restauração concluído!"
fi

echo "Todos os testes concluídos!"