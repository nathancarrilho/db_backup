#!/bin/bash
set -e

# Verificar se foi fornecido um arquivo de backup
if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <arquivo_backup>"
    echo "Exemplo: $0 /mnt/backups/bica-backup-2025-04-07_184122.dump.enc"
    exit 1
fi

BACKUP_FILE=$1
TEMP_DIR="/tmp/bica-restore"

# Obter a chave de encriptação diretamente do contêiner
echo "Obtendo chave de encriptação do contêiner..."
ENCRYPTION_KEY=$(docker exec bica-backup grep -E "^ENCRYPTION_KEY=" /app/.env | cut -d= -f2)

if [ -z "$ENCRYPTION_KEY" ]; then
    echo "ERRO: Não foi possível obter a chave de encriptação do contêiner."
    exit 1
fi

echo "Iniciando restauração do backup: $BACKUP_FILE"

# Criar diretório temporário
mkdir -p $TEMP_DIR

# Decriptar o arquivo de backup
DECRYPTED_FILE="$TEMP_DIR/backup.dump"
echo "Decriptando backup..."
openssl enc -aes-256-cbc -d -salt -in "$BACKUP_FILE" \
  -out "$DECRYPTED_FILE" -pass "pass:$ENCRYPTION_KEY"

echo "Backup decriptado com sucesso!"

# Confirmar a restauração
echo "ATENÇÃO: A restauração irá substituir a base de dados atual."
echo "Deseja continuar? (s/n)"
read resposta

if [ "$resposta" = "s" ]; then
    echo "Restaurando backup para a base de dados postgres..."
    
    # Restaurar o backup
    docker exec -i bica-postgres pg_restore \
      -U postgres \
      -d postgres \
      --clean \
      --if-exists < "$DECRYPTED_FILE"
    
    echo "Restauração concluída com sucesso!"
else
    echo "Restauração cancelada pelo usuário."
fi

# Limpeza
echo "Limpando arquivos temporários..."
rm -rf "$TEMP_DIR"

echo "Processo de restauração finalizado."