# Oracle 19c — Guia de Configuração no Docker (PT-BR)

## 1. Baixar a imagem
```
docker pull laynerain/oracle19c:19.3.0
```

## 2. Renomear a imagem (retag)
Formato:
```
docker image tag <imagem_original:tag_original> <seuUsuarioDockerHub>/<novoNome>:<novaTag>
```

Exemplo:
```
docker image tag laynerain/oracle19c:19.3.0 otherName/oracle19c:newTag
```

## 3. Iniciar o contêiner
```
docker run -d --name oracle19c `
  -p 1521:1521 `
  -p 5500:5500 `
  -e ORACLE_SID=ORCLCDB `
  -e ORACLE_PDB=layne `
  -e ORACLE_PWD='qwe#1234' `
  -e ORACLE_EDITION=standard `
  -e ORACLE_CHARACTERSET=AL32UTF8 `
  -e TZ=Asia/Shanghai `
  -v E:\Docker\oracle19c\data:/opt/oracle/oradata `
  -v E:\Docker\oracle19c\logs:/opt/oracle/diag `
  --memory=2g `
  --cpus=2 `
  laynerain/oracle19c:19.3.0
```

## 4. Significado dos parâmetros

### Variáveis / Parâmetros | Descrição | Exemplo

| Variável/Parâmetro | Função | Exemplo |
|--------------------|--------|---------|
| ORACLE_SID | Nome da instância do contêiner. | ORCLCDB |
| ORACLE_PDB | Nome da PDB (banco plugável). | layne |
| ORACLE_PWD | Senha dos usuários system/sys/pdbadmin. | qwe#1234 |
| ORACLE_EDITION | Edição do Oracle. | standard / enterprise |
| ORACLE_CHARACTERSET | Charset do banco. | AL32UTF8 |
| TZ | Timezone. | Asia/Shanghai |
| -v /host:/opt/oracle/oradata | Persistência dos dados. | E:\Docker\oracle19c\data |
| -v /host:/opt/oracle/diag | Persistência dos logs. | E:\Docker\oracle19c\logs |
| -p 1521:1521 | Porta Oracle. | 1521 |
| -p 5500:5500 | Enterprise Manager. | 5500 |
| --memory / --cpus | Limite de recursos. | 2GB/2CPU |

## 5. Persistência e segurança
- ORACLE_PWD define a senha dos administradores SYS/SYSTEM.
- Volumes garantem que os dados não serão perdidos.
- Sempre mantenha backups das pastas `oradata` e `diag`.

## 6. Logs
```
docker logs -f oracle19c
```

## 7. Entrar no contêiner
```
docker exec -it oracle19c bash
```

## 8. Acessar Enterprise Manager
```
http://<host>:5500/em
```
Usuário: sys  
Senha: definida em ORACLE_PWD

## 9. Observações finais
- Ajuste memória/CPU conforme sua máquina.
- Use senhas fortes.
- Sempre utilize volumes para persistência.
- A primeira inicialização pode demorar devido à criação do banco.
