#!/bin/bash

# Script de Validação do Oracle 19c no Docker
# Uso: ./validate-oracle.sh

set -e

echo "=========================================="
echo "Validação do Oracle 19c - Docker"
echo "=========================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Verificar se o container está rodando
echo "1. Verificando status do container..."
if docker compose ps | grep -q "oracle19c.*Up"; then
    echo -e "${GREEN}✓ Container está rodando${NC}"
    docker compose ps oracle19c
else
    echo -e "${RED}✗ Container não está rodando${NC}"
    exit 1
fi
echo ""

CONTAINER_ID=$(docker compose ps -q oracle19c 2>/dev/null || true)
if [ -z "$CONTAINER_ID" ]; then
    echo -e "${RED}✗ Não foi possível identificar o container do Oracle via docker compose${NC}"
    exit 1
fi

# 2. Verificar healthcheck
echo "2. Verificando healthcheck..."
HEALTH=$(docker inspect "$CONTAINER_ID" --format='{{.State.Health.Status}}' 2>/dev/null || echo "none")
if [ "$HEALTH" = "healthy" ]; then
    echo -e "${GREEN}✓ Container está saudável${NC}"
elif [ "$HEALTH" = "starting" ]; then
    echo -e "${YELLOW}⚠ Container ainda está inicializando (isso é normal, pode levar alguns minutos)${NC}"
else
    echo -e "${YELLOW}⚠ Status de saúde: $HEALTH${NC}"
fi
echo ""

# 3. Verificar logs recentes
echo "3. Últimas linhas dos logs (verificando erros)..."
ERRORS=$(docker compose logs --tail=20 oracle19c 2>&1 | grep -i "error\|failed\|cannot" | tail -5 || true)
if [ -z "$ERRORS" ]; then
    echo -e "${GREEN}✓ Nenhum erro crítico encontrado nos logs recentes${NC}"
else
    echo -e "${YELLOW}⚠ Possíveis problemas encontrados:${NC}"
    echo "$ERRORS"
fi
echo ""

# 4. Verificar se o listener está ativo
echo "4. Verificando Oracle Listener..."
LISTENER_STATUS=$(docker compose exec -T oracle19c lsnrctl status 2>/dev/null | grep -i "listening\|ready" || echo "")
if [ -n "$LISTENER_STATUS" ]; then
    echo -e "${GREEN}✓ Listener está ativo${NC}"
    docker compose exec -T oracle19c lsnrctl status | head -15
else
    echo -e "${YELLOW}⚠ Listener pode ainda estar inicializando${NC}"
fi
echo ""

# 5. Testar conexão SQL*Plus (se disponível)
echo "5. Testando conexão ao banco de dados..."
SQL_TEST=$(docker compose exec -T oracle19c sqlplus -s /nolog <<EOF 2>&1
conn sys/Oracle123Secure@localhost:1521/ORCLCDB as sysdba
SELECT 'CONNECTION_OK' FROM DUAL;
exit;
EOF
)
if echo "$SQL_TEST" | grep -q "CONNECTION_OK\|Connected"; then
    echo -e "${GREEN}✓ Conexão ao banco de dados bem-sucedida${NC}"
else
    echo -e "${YELLOW}⚠ Banco ainda pode estar inicializando ou SQL*Plus não disponível${NC}"
    echo "   (Isso é normal na primeira inicialização, pode levar 5-10 minutos)"
fi
echo ""

# 6. Verificar portas
echo "6. Verificando portas expostas..."
if netstat -tuln 2>/dev/null | grep -q ":1521.*LISTEN" || ss -tuln 2>/dev/null | grep -q ":1521"; then
    echo -e "${GREEN}✓ Porta 1521 (Oracle) está escutando${NC}"
else
    echo -e "${YELLOW}⚠ Porta 1521 não encontrada (pode estar ainda inicializando)${NC}"
fi

if netstat -tuln 2>/dev/null | grep -q ":5500.*LISTEN" || ss -tuln 2>/dev/null | grep -q ":5500"; then
    echo -e "${GREEN}✓ Porta 5500 (Enterprise Manager) está escutando${NC}"
else
    echo -e "${YELLOW}⚠ Porta 5500 não encontrada${NC}"
fi
echo ""

# 7. Informações de acesso
echo "=========================================="
echo "Informações de Acesso:"
echo "=========================================="
echo ""
echo "📊 Enterprise Manager:"
echo "   URL: http://localhost:5500/em"
echo "   Usuário: sys"
echo "   Senha: (verifique no arquivo .env - variável ORACLE_PWD)"
echo ""
echo "🗄️  Conexão SQL:"
echo "   Host: localhost"
echo "   Port: 1521"
echo "   SID: ORCLCDB"
echo "   Service Name: ORCLPDB1 (para PDB)"
echo "   Usuário: sys (como sysdba) ou system"
echo ""
echo "📝 Comandos úteis:"
echo "   Ver logs: docker compose logs -f oracle19c"
echo "   Entrar no container: docker compose exec oracle19c bash"
echo "   Parar: docker compose stop"
echo "   Iniciar: docker compose start"
echo "   Reiniciar: docker compose restart"
echo ""

# Resumo final
if [ "$HEALTH" = "healthy" ]; then
    echo -e "${GREEN}=========================================="
    echo "✓ Oracle está funcionando corretamente!"
    echo "   Status de saúde: $HEALTH"
    echo "==========================================${NC}"
    exit 0
else
    echo -e "${YELLOW}=========================================="
    echo "⚠ Oracle ainda está inicializando..."
    echo "   Status de saúde: $HEALTH"
    echo "   Aguarde alguns minutos e execute novamente"
    echo "   Monitore os logs com: docker compose logs -f oracle19c"
    echo "==========================================${NC}"
    exit 0
fi
