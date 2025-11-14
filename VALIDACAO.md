# Guia de Validação do Oracle 19c

## ⚠️ Importante: Permissões dos Volumes

Antes de validar, certifique-se de que os diretórios têm as permissões corretas:

```bash
# Execute com sudo (necessário para alterar permissões)
sudo chown -R 54321:54321 data/
sudo chmod -R 755 data/
```

## 🔍 Validação Passo a Passo

### 1. Verificar Status do Container

```bash
docker compose ps
```

**Resultado esperado:** Status deve mostrar `Up` e `healthy` (ou `starting` se ainda estiver inicializando)

### 2. Verificar Logs

```bash
# Ver logs em tempo real
docker compose logs -f oracle19c

# Ver últimas 50 linhas
docker compose logs --tail=50 oracle19c
```

**O que procurar:**
- ✅ `DATABASE IS READY TO USE!` - Banco pronto
- ✅ `Listener started` - Listener ativo
- ❌ `ERROR` ou `DATABASE SETUP WAS NOT SUCCESSFUL` - Problemas

### 3. Verificar Oracle Listener

```bash
docker compose exec oracle19c lsnrctl status
```

**Resultado esperado:** Deve mostrar o listener ativo e escutando na porta 1521

### 4. Testar Conexão SQL*Plus

```bash
docker compose exec oracle19c sqlplus sys/Oracle123Secure@localhost:1521/ORCLCDB as sysdba
```

Dentro do SQL*Plus, execute:
```sql
SELECT 'Oracle está funcionando!' FROM DUAL;
EXIT;
```

**Nota:** Substitua `Oracle123Secure` pela senha definida no seu `.env`

### 5. Verificar Portas

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

### 6. Testar Enterprise Manager (Web)

Abra no navegador:
```
http://localhost:5500/em
```

**Credenciais:**
- Usuário: `sys`
- Senha: (a mesma definida em `ORACLE_PWD` no `.env`)
- Conectar como: `SYSDBA`

### 7. Usar o Script de Validação Automática

```bash
./validate-oracle.sh
```

Este script executa todas as verificações acima automaticamente.

## ⏱️ Tempo de Inicialização

**Importante:** A primeira inicialização do Oracle pode levar **5-15 minutos** dependendo da sua máquina. 

Sinais de que ainda está inicializando:
- Healthcheck mostra `starting`
- Logs mostram `Copying database files` ou `Creating database`
- Listener não mostra serviços registrados

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

### Problema: Não consegue conectar

**Solução:**
1. Aguarde alguns minutos (banco ainda inicializando)
2. Verifique se o listener está ativo: `docker compose exec oracle19c lsnrctl status`
3. Verifique a senha no arquivo `.env`

## 📊 Comandos Úteis

```bash
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

# Remover tudo (CUIDADO: apaga dados)
docker compose down -v
```

## ✅ Checklist de Validação

- [ ] Container está rodando (`docker compose ps`)
- [ ] Logs não mostram erros críticos
- [ ] Listener está ativo (`lsnrctl status`)
- [ ] Porta 1521 está escutando
- [ ] Porta 5500 está escutando
- [ ] Conexão SQL*Plus funciona
- [ ] Enterprise Manager acessível via browser
- [ ] Healthcheck mostra `healthy` (após inicialização completa)

