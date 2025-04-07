#!/bin/bash
set -e

# Carregar variáveis de ambiente manualmente para evitar problemas de formatação
if [ -f /app/.env ]; then
  # Usar grep para extrair cada variável individualmente
  DB_HOST=$(grep -E "^DB_HOST=" /app/.env | cut -d= -f2)
  DB_PORT=$(grep -E "^DB_PORT=" /app/.env | cut -d= -f2)
  DB_USER=$(grep -E "^DB_USER=" /app/.env | cut -d= -f2)
  DB_PASSWORD=$(grep -E "^DB_PASSWORD=" /app/.env | cut -d= -f2)
  DB_NAME=$(grep -E "^DB_NAME=" /app/.env | cut -d= -f2)
  RETENTION_DAYS=$(grep -E "^RETENTION_DAYS=" /app/.env | cut -d= -f2)
  ENCRYPTION_KEY=$(grep -E "^ENCRYPTION_KEY=" /app/.env | cut -d= -f2)
else
  echo "ERRO: Arquivo /app/.env não encontrado!"
  exit 1
fi

# Verificar se todas as variáveis necessárias estão definidas
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DB_NAME" ]; then
  echo "ERRO: Variáveis de ambiente incompletas. Verifique o arquivo .env"
  echo "DB_HOST=$DB_HOST"
  echo "DB_PORT=$DB_PORT"
  echo "DB_USER=$DB_USER"
  echo "DB_NAME=$DB_NAME"
  echo "DB_PASSWORD=[oculto por segurança]"
  exit 1
fi

# Definir data/hora para o nome do arquivo (mais detalhado com segundos)
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
BACKUP_FILENAME="bica-backup-${TIMESTAMP}"
BACKUP_PATH="/backup/${BACKUP_FILENAME}"
RETENTION_DAYS=${RETENTION_DAYS:-7}

echo "Iniciando backup do PostgreSQL em: $(date)"
echo "Host: ${DB_HOST}"
echo "Porta: ${DB_PORT}"
echo "Banco de dados: ${DB_NAME}"
echo "Usuário: ${DB_USER}"
echo "Diretório de backup: ${BACKUP_PATH}"
echo "Retenção de backup: ${RETENTION_DAYS} dias"

# Limpar diretório temporário se existir
if [ -d "${BACKUP_PATH}" ]; then
  echo "Removendo diretório de backup existente..."
  rm -rf "${BACKUP_PATH}"
fi

# Criar diretório temporário
mkdir -p "${BACKUP_PATH}"

# Verificar permissões
echo "Verificando permissões do diretório de backup..."
if [ ! -w "${BACKUP_PATH}" ]; then
  echo "ERRO: Sem permissão de escrita no diretório ${BACKUP_PATH}"
  exit 1
fi

# Realizar pg_dump
echo "Executando pg_dump..."
PGPASSWORD="$DB_PASSWORD" pg_dump \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -U "$DB_USER" \
  -F c \
  -f "${BACKUP_PATH}.dump" \
  "$DB_NAME"

echo "Backup concluído com sucesso!"

# Encriptar o backup diretamente
echo "Encriptando backup..."
if [ -n "$ENCRYPTION_KEY" ]; then
  openssl enc -aes-256-cbc -salt -in "${BACKUP_PATH}.dump" \
    -out "${BACKUP_PATH}.dump.enc" -pass "pass:${ENCRYPTION_KEY}"
else
  echo "AVISO: Chave de encriptação não definida. Backup não será encriptado."
  cp "${BACKUP_PATH}.dump" "${BACKUP_PATH}.dump.enc"
fi

# Mover para diretório final com montagem persistente
echo "Movendo backup para armazenamento persistente..."
cp "${BACKUP_PATH}.dump.enc" "/mnt/backups/${BACKUP_FILENAME}.dump.enc"

# Verificar se o backup foi copiado com sucesso
if [ -f "/mnt/backups/${BACKUP_FILENAME}.dump.enc" ]; then
  echo "Backup movido com sucesso para /mnt/backups/"
else
  echo "ERRO: Falha ao mover o backup para /mnt/backups/"
  exit 1
fi

# Limpeza dos arquivos temporários
echo "Limpando arquivos temporários..."
rm -rf "${BACKUP_PATH}" "${BACKUP_PATH}.dump" "${BACKUP_PATH}.dump.enc"

# Se for o backup das 03:00 AM, limpar backups antigos
CURRENT_HOUR=$(date +"%H")
if [[ "${CURRENT_HOUR}" == "03" ]]; then
  echo "Removendo backups mais antigos que ${RETENTION_DAYS} dias..."
  find /mnt/backups -name "bica-backup-*.dump.enc" -type f -mtime +${RETENTION_DAYS} -delete
fi

echo "Processo de backup finalizado em: $(date)"
echo "Listando backups em /mnt/backups/:"
ls -la /mnt/backups/