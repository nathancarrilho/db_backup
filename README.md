# Sistema de Backup Automatizado para PostgreSQL

Este projeto implementa uma solução completa para automatizar e gerenciar backups encriptados de bancos de dados PostgreSQL, utilizando contêineres Docker. O sistema realiza backups diários, mantém uma política de retenção configurável e oferece ferramentas para restauração.

## Índice

- [Visão Geral](#visão-geral)
- [Requisitos](#requisitos)
- [Instalação](#instalação)
- [Configuração](#configuração)
- [Uso](#uso)
- [Testando o Sistema](#testando-o-sistema)
- [Manutenção](#manutenção)
- [Resolução de Problemas](#resolução-de-problemas)

## Visão Geral

O sistema de backup realiza as seguintes operações:
- Backup automatizado duas vezes ao dia (03:00 AM e 14:00 PM UTC)
- Encriptação dos backups com AES-256-CBC
- Armazenamento em localização persistente (/mnt/backups)
- Rotação automática de backups antigos
- Fácil restauração quando necessário

## Requisitos

- Docker e Docker Compose
- Servidor Linux com acesso ao PostgreSQL
- Diretório `/mnt/backups` com permissões de leitura/escrita

## Instalação

1. Clone o repositório:

```bash
git clone https://github.com/nathancarrilho/db_backup.git
cd db_backup
```

2. Torne os scripts executáveis:

```bash
chmod +x *.sh
```

3. Execute o script de configuração:

```bash
./setup.sh
```

4. Inicie os contêineres:

```bash
docker-compose up -d
```

## Configuração

### Arquivo .env

O sistema utiliza um arquivo `.env` para configuração. Um exemplo é fornecido, mas você deve ajustá-lo para suas necessidades:

```bash
# Criar o diretório config se necessário
mkdir -p config

# Criar arquivo .env personalizado
cat > config/.env << EOF
DB_HOST=postgres
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=postgres
RETENTION_DAYS=7
ENCRYPTION_KEY=$(openssl rand -base64 32)
EOF
```

### Usando o Vault
TODO

## Uso

### Verificar Status dos Contêineres

```bash
docker ps
```

### Logs do Contêiner de Backup

```bash
docker logs -f bica-backup
```

### Executar Backup Manualmente

```bash
docker exec -it bica-backup /app/backup.sh
```

### Listar Backups Existentes

```bash
docker exec -it bica-backup ls -la /mnt/backups/
```

### Restaurar um Backup

```bash
./restore.sh /mnt/backups/nome-do-arquivo-backup.dump.enc
```

## Testando o Sistema

Aqui está um guia passo a passo para testar todas as funcionalidades do sistema de backup:

### 1. Teste de Conectividade

Verifique se o contêiner de backup consegue se conectar ao PostgreSQL:

```bash
docker exec -it bica-backup bash -c "PGPASSWORD=postgres psql -h postgres -p 5432 -U postgres -c 'SELECT version();'"
```

### 2. Criar Dados de Teste

Crie uma tabela de teste e insira alguns dados:

```bash
docker exec -it bica-postgres psql -U postgres -c "
CREATE TABLE teste_backup (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    data_criacao TIMESTAMP DEFAULT NOW()
);

INSERT INTO teste_backup (nome) VALUES 
('Registro 1'),
('Registro 2'),
('Registro 3');
"
```

### 3. Verificar os Dados

Confirme que os dados foram inseridos:

```bash
docker exec -it bica-postgres psql -U postgres -c "SELECT * FROM teste_backup;"
```

### 4. Realizar Backup Manual

Execute um backup manual:

```bash
docker exec -it bica-backup /app/backup.sh
```

### 5. Verificar Backup Gerado

Liste os arquivos de backup:

```bash
docker exec -it bica-backup ls -la /mnt/backups/
```

### 6. Simular Perda de Dados

Remova a tabela para simular perda de dados:

```bash
docker exec -it bica-postgres psql -U postgres -c "DROP TABLE teste_backup;"
```

Confirme que os dados foram removidos:

```bash
docker exec -it bica-postgres psql -U postgres -c "SELECT * FROM teste_backup;" 2>/dev/null || echo "Tabela não existe mais"
```

### 7. Restaurar Backup

```bash
# Obtenha o nome do arquivo de backup mais recente
BACKUP_FILE=$(ls -t /mnt/backups/bica-backup-*.dump.enc | head -1)

# Restaure o backup
./restore.sh $BACKUP_FILE
```

Quando solicitado, digite 's' para confirmar a restauração.

### 8. Verificar Dados Restaurados

```bash
docker exec -it bica-postgres psql -U postgres -c "SELECT * FROM teste_backup;"
```

Os dados originais devem estar de volta, confirmando que o processo de backup e restauração está funcionando corretamente.

## Manutenção

### Remover Backups Antigos Manualmente

```bash
docker exec -it bica-backup find /mnt/backups -name "bica-backup-*.dump.enc" -type f -mtime +7 -delete
```

### Verificar Espaço em Disco

```bash
docker exec -it bica-backup du -sh /mnt/backups/
```

### Reiniciar os Serviços

```bash
docker-compose restart
```

### Parar Todos os Serviços

```bash
docker-compose down
```

## Resolução de Problemas

### Backup Falha com Erro de Conexão

Verifique as credenciais e a conectividade:

```bash
docker exec -it bica-backup bash -c "PGPASSWORD=postgres pg_isready -h postgres -p 5432 -U postgres"
```

### Erro "Database Não Existe"

Verifique os bancos de dados disponíveis:

```bash
docker exec -it bica-backup bash -c "PGPASSWORD=postgres psql -h postgres -p 5432 -U postgres -c '\l'"
```

### Erro "Bad Decrypt" na Restauração

O erro indica um problema com a chave de encriptação. Recrie o script de restauração para usar a chave correta do contêiner:

```bash
./restore.sh /mnt/backups/nome-do-backup.dump.enc
```

### Erro de Permissão no Diretório de Backup

Verifique e corrija as permissões:

```bash
docker exec -it bica-backup bash -c "mkdir -p /mnt/backups && chmod 777 /mnt/backups"
```

---

## Estrutura do Projeto

- `backup.sh`: Script principal de backup
- `restore.sh`: Script para restauração de backups
- `entrypoint.sh`: Script de inicialização do contêiner
- `Dockerfile`: Definição da imagem Docker
- `docker-compose.yml`: Configuração dos serviços
- `.env.example`: Modelo para variáveis de ambiente
- `setup.sh`: Script de configuração inicial

---

Este sistema de backup automatizado oferece uma solução robusta e confiável para garantir a segurança dos seus dados PostgreSQL.
