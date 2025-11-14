# Oracle 19c Docker

Este repositório contém uma configuração Docker Compose para executar o Oracle Database 19c em um ambiente containerizado, facilitando o desenvolvimento e testes locais.

## 📋 Índice

- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Configuração](#configuração)
- [Uso](#uso)
- [Scripts Auxiliares](#scripts-auxiliares)
- [Validação](#validação)
- [Informações de Acesso](#informações-de-acesso)
- [Solução de Problemas](#solução-de-problemas)
- [Comandos Úteis](#comandos-úteis)

## 🔧 Pré-requisitos

- Docker Engine 20.10+
- Docker Compose 2.0+
- Pelo menos 2GB de RAM disponível (recomendado 4GB+)
- Pelo menos 10GB de espaço em disco livre

## 🚀 Instalação

1. **Clone ou baixe este repositório**

2. **Configure as variáveis de ambiente**

   Copie o arquivo de exemplo e ajuste conforme necessário:
   ```bash
   cp env.example .env
   ```

3. **Ajuste as permissões dos diretórios de dados** (importante!)

   ```bash
   sudo chown -R 54321:54321 data/
   sudo chmod -R 755 data/
   ```

   **Nota:** Isso é necessário porque o Oracle roda com o usuário UID 54321 dentro do container.

## ⚙️ Configuração

Edite o arquivo `.env` para personalizar as configurações:

### Portas
- `ORACLE_PORT`: Porta do Oracle Database (padrão: 1521)
- `EM_PORT`: Porta do Enterprise Manager (padrão: 5500)

### Configurações do Banco de Dados
- `ORACLE_SID`: Nome da instância do container (padrão: ORCLCDB)
- `ORACLE_PDB`: Nome da PDB - Pluggable Database (padrão: ORCLPDB1)
- `ORACLE_PWD`: **Senha dos usuários sys/system/pdbadmin** (obrigatório)
- `ORACLE_EDITION`: Edição do Oracle - `standard` ou `enterprise` (padrão: standard)
- `ORACLE_CHARACTERSET`: Charset do banco (padrão: AL32UTF8)

### Timezone
- `TZ`: Timezone (padrão: America/Sao_Paulo)

### Limites de Recursos
- `MEMORY_LIMIT`: Limite de memória (padrão: 2g)
- `MEMORY_RESERVATION`: Reserva de memória (padrão: 1g)
- `CPUS_LIMIT`: Limite de CPUs (padrão: 2)
- `CPUS_RESERVATION`: Reserva de CPUs (padrão: 1)

## 🎯 Uso

### Iniciar o Oracle

```bash
docker compose up -d
```

## 🛠️ Construção e Inicialização do Container

Siga esta sequência para criar o banco do zero:

1. **Configurar variáveis:** `cp env.example .env` e ajuste `ORACLE_PWD`, portas e limites.
2. **Ajustar permissões dos dados:** `sudo chown -R 54321:54321 data/ && sudo chmod -R 755 data/`.
3. **Scripts de bootstrap:** mantenha a pasta `scripts/` (montada em `/opt/oracle/scripts`). O SQL `scripts/startup/disable_maintenance_plan.sql` desabilita as janelas de manutenção e remove o plano `DEFAULT_MAINTENANCE_PLAN`, evitando mensagens constantes nos logs.
4. **Subir o container:** `docker compose up -d`.
5. **Validar:** execute `./validate-oracle.sh` e confirme que o status está `healthy`, o listener responde e a conexão SQL*Plus passa.

> Para reconstruir tudo de maneira automatizada, use `sudo ./reset-oracle.sh`, que aplica todos os passos acima e acompanha os logs até o banco ficar pronto.

### Parar o Oracle

```bash
docker compose stop
```

### Reiniciar o Oracle

```bash
docker compose restart
```

### Ver logs em tempo real

```bash
docker compose logs -f oracle19c
```

### Parar e remover tudo (⚠️ CUIDADO: apaga dados)

```bash
docker compose down -v
```

## 📜 Scripts Auxiliares

### `validate-oracle.sh`

Script de validação automática que verifica:
- Status do container
- Healthcheck
- Logs recentes
- Oracle Listener
- Conexão ao banco de dados
- Portas expostas

**Uso:**
```bash
chmod +x validate-oracle.sh
./validate-oracle.sh
```

### `reset-oracle.sh`

Script para resetar completamente o Oracle (limpar dados e recriar).

**⚠️ ATENÇÃO:** Este script apaga todos os dados do banco!

**Uso:**
```bash
chmod +x reset-oracle.sh
sudo ./reset-oracle.sh
```

O script:
1. Para o container
2. Remove todos os dados antigos
3. Ajusta permissões
4. Inicia o Oracle novamente
5. Monitora os logs

### `scripts/startup/disable_maintenance_plan.sql`

Executado automaticamente a cada inicialização (via `/opt/oracle/scripts/startup`). Ele desabilita todas as janelas padrão (`MONDAY_WINDOW`, `WEEKEND_WINDOW`, etc.), força o grupo `SYS.MAINTENANCE_WINDOW_GROUP` a permanecer desligado e zera `RESOURCE_MANAGER_PLAN`, evitando que o Resource Manager padrão seja aplicado e que novas mensagens “Setting Resource Manager plan...” apareçam nos logs.

## ✅ Validação

### Validação Manual

Consulte o arquivo [VALIDACAO.md](./VALIDACAO.md) para um guia detalhado passo a passo.

### Validação Automática

Execute o script de validação:
```bash
./validate-oracle.sh
```

### ⏱️ Tempo de Inicialização

**Importante:** A primeira inicialização do Oracle pode levar **5-15 minutos** dependendo da sua máquina.

Sinais de que ainda está inicializando:
- Healthcheck mostra `starting`
- Logs mostram `Copying database files` ou `Creating database`
- Listener não mostra serviços registrados

## 🔐 Informações de Acesso

### Enterprise Manager (Web)

- **URL:** http://localhost:5500/em
- **URL (com proxy reverso/HTTPS obrigatório):** https://localhost:5500/em
- **Usuário:** `sys`
- **Senha:** (valor definido em `ORACLE_PWD` no arquivo `.env`)
- **Conectar como:** `SYSDBA`

### Conexão SQL

- **Host:** `localhost`
- **Port:** `1521`
- **SID:** `ORCLCDB`
- **Service Name:** `ORCLPDB1` (para PDB)
- **Usuários:** 
  - `sys` (como sysdba)
  - `system`
- `pdbadmin` (para PDB)
- **Senha:** (valor definido em `ORACLE_PWD` no arquivo `.env`)

### Exemplo de Conexão SQL*Plus

```bash
docker compose exec oracle19c sqlplus sys/SUA_SENHA@localhost:1521/ORCLCDB as sysdba
```

Dentro do SQL*Plus:
```sql
SELECT 'Oracle está funcionando!' FROM DUAL;
EXIT;
```

## 💾 Schema `laraveldb` para o Laravel

### 1. Criar o usuário e a tabela de teste

Execute os comandos abaixo dentro do container (as credenciais usam os valores padrão de `.env.example`):

```bash
# 1. Criar o usuário/schema dentro da PDB ORCLPDB1
docker compose exec -T oracle19c sqlplus -s sys/Oracle123#Secure@localhost:1521/ORCLPDB1 as sysdba <<'SQL'
CREATE USER laraveldb IDENTIFIED BY "Oracle123#Secure" DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP;
GRANT CONNECT, RESOURCE TO laraveldb;
ALTER USER laraveldb QUOTA UNLIMITED ON USERS;
SQL

# 2. Conectar como laraveldb e criar a tabela de teste
docker compose exec -T oracle19c sqlplus -s laraveldb/Oracle123#Secure@localhost:1521/ORCLPDB1 <<'SQL'
CREATE TABLE usuarios (
    id   NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY,
    nome VARCHAR2(255) NOT NULL,
    CONSTRAINT usuarios_pk PRIMARY KEY (id)
);
SQL
```

O campo `id` usa `GENERATED BY DEFAULT ON NULL AS IDENTITY`, o equivalente Oracle para `AUTO_INCREMENT`. Esse schema fica pronto para ser consumido por uma aplicação Laravel ou para testes manuais.

### 2. Conectando o DataGrip com o usuário `laraveldb`

1. `Connection type`: **Service Name**
2. `Host`: `localhost`
3. `Port`: `1521`
4. `Service`: `ORCLPDB1`
5. `Driver`: `Thin`
6. `Authentication`: `User & Password`
7. `User`: `laraveldb`
8. `Password`: `Oracle123#Secure` (ou o valor atualizado de `ORACLE_PWD`)
9. O URL gerado fica `jdbc:oracle:thin:@//localhost:1521/ORCLPDB1`

![Configuração DataGrip](datagrip.png)

#### Visualizando o schema

1. **Conexão dedicada:** duplique a conexão existente e altere o usuário para `laraveldb`. Ao expandir a nova conexão, o painel *Database* exibirá `Schemas > LARAVELDB > Tables > USUARIOS`.
2. **Via `pdbadmin` ou `sys`:** na conexão atual, clique no ícone de filtro (funil) em *Schemas* e adicione `LARAVELDB`. Depois expanda `Schemas` e procure a tabela em `LARAVELDB > Tables`.
3. Sempre que criar objetos novos, use `Ctrl+F5` (Refresh) para atualizar o cache de metadados do DataGrip.

#### Acessando o Enterprise Manager (EM Express)

- URL padrão: `http://localhost:5500/em`. Se houver proxy reverso forçando HTTPS, use `https://localhost:5500/em`.
- Credenciais com privilégios máximos:
  - `Username`: `sys`
  - `Password`: `Oracle123#Secure` (ou o valor de `ORACLE_PWD`)
  - `Container Name`: `ORCLPDB1` (ou `ORCLCDB` para o container raiz)
  - Marque “Connect as SYSDBA” quando solicitado e repita usuário/senha caso o navegador exiba um popup de autenticação.

### Exemplo de Conexão JDBC

```
jdbc:oracle:thin:@localhost:1521:ORCLCDB
```

Para PDB:
```
jdbc:oracle:thin:@localhost:1521/ORCLPDB1
```

## 🐛 Solução de Problemas

### Problema: "Cannot create directory /opt/oracle/oradata"

**Solução:**
```bash
sudo chown -R 54321:54321 data/
sudo chmod -R 755 data/
docker compose restart
```

### Problema: Container para logo após iniciar

**Solução:**
```bash
# Ver logs detalhados
docker compose logs oracle19c

# Verificar recursos disponíveis
docker stats oracle19c
```

Verifique se há memória suficiente disponível e ajuste os limites no arquivo `.env` se necessário.

### Problema: Não consegue conectar

**Solução:**
1. Aguarde alguns minutos (banco ainda pode estar inicializando)
2. Verifique se o listener está ativo: `docker compose exec oracle19c lsnrctl status`
3. Verifique a senha no arquivo `.env`
4. Execute o script de validação: `./validate-oracle.sh`

### Problema: Healthcheck sempre falha

O healthcheck pode levar alguns minutos para passar na primeira inicialização. Monitore os logs:
```bash
docker compose logs -f oracle19c
```

Procure por mensagens como:
- ✅ `DATABASE IS READY TO USE!` - Banco pronto
- ✅ `Listener started` - Listener ativo
- ❌ `ERROR` ou `DATABASE SETUP WAS NOT SUCCESSFUL` - Problemas

## 📊 Comandos Úteis

### Gerenciamento do Container

```bash
# Ver status
docker compose ps

# Ver logs
docker compose logs -f oracle19c

# Entrar no container
docker compose exec oracle19c bash

# Ver uso de recursos
docker stats oracle19c

# Parar o Oracle
docker compose stop

# Iniciar o Oracle
docker compose start

# Reiniciar o Oracle
docker compose restart
```

### Comandos Oracle

```bash
# Verificar status do listener
docker compose exec oracle19c lsnrctl status

# Iniciar listener (se necessário)
docker compose exec oracle19c lsnrctl start

# Conectar via SQL*Plus
docker compose exec oracle19c sqlplus sys/SUA_SENHA@localhost:1521/ORCLCDB as sysdba
```

### Verificar Portas

```bash
# Verificar porta 1521 (Oracle)
netstat -tuln | grep 1521
# ou
ss -tuln | grep 1521

# Verificar porta 5500 (Enterprise Manager)
netstat -tuln | grep 5500
# ou
ss -tuln | grep 5500
```

## 📝 Checklist de Validação

- [ ] Container está rodando (`docker compose ps`)
- [ ] Logs não mostram erros críticos
- [ ] Listener está ativo (`lsnrctl status`)
- [ ] Porta 1521 está escutando
- [ ] Porta 5500 está escutando
- [ ] Conexão SQL*Plus funciona
- [ ] Enterprise Manager acessível via browser
- [ ] Healthcheck mostra `healthy` (após inicialização completa)

## 🔒 Segurança

- **Sempre use senhas fortes** para `ORACLE_PWD`
- **Não commite o arquivo `.env`** no controle de versão
- **Mantenha backups** das pastas `data/oradata` e `data/diag`
- Este ambiente é adequado para **desenvolvimento e testes locais**. Para produção, considere configurações adicionais de segurança.

## 📚 Recursos Adicionais

- [Documentação Oficial do Oracle Database](https://docs.oracle.com/en/database/oracle/oracle-database/19/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Guia de Validação Detalhado](./VALIDACAO.md)

## 📄 Licença

Este projeto utiliza a imagem Docker `laynerain/oracle19c:19.3.0`. Consulte os termos de licença do Oracle Database para uso em produção.

---

**Nota:** Este é um ambiente de desenvolvimento/testes. Para ambientes de produção, considere configurações adicionais de segurança, backup e monitoramento.
