# 🚀 Guia de Scripts para Deploy GCP

## 📋 Scripts Disponíveis

### 1. **test-gcp-config.sh** - Verificação Rápida ✅
```bash
./scripts/test-gcp-config.sh
```
- ✅ **Testa** se a configuração Terraform está funcionando
- ✅ **Valida** syntax e configuração
- ✅ **Mostra** resumo do que será feito
- ✅ **Não aplica** mudanças (apenas testa)

### 2. **smart-deploy-gcp.sh** - Deploy Inteligente 🤖 (Recomendado)
```bash
./scripts/smart-deploy-gcp.sh
```
- 🤖 **Detecta automaticamente** recursos existentes
- 🔄 **Configura data sources** automaticamente
- 🚀 **Aplica apenas** recursos que não existem
- 💡 **Totalmente automatizado**

### 3. **import-gcp-resources.sh** - Importação Manual
```bash
./scripts/import-gcp-resources.sh
```
- 📥 **Importa** recursos existentes para o estado Terraform
- 🔧 **Útil** para migração gradual
- ⚙️ **Manual** - requer conhecimento técnico

### 4. **cleanup-gcp-resources.sh** - Limpeza (⚠️ CUIDADO!)
```bash
./scripts/cleanup-gcp-resources.sh
```
- ⚠️ **REMOVE** recursos existentes no GCP
- 🗑️ **Irreversível** - use apenas se necessário
- 🔒 **Múltiplas confirmações** de segurança

### 5. **apply-gcp-terraform.sh** - Aplicação Segura
```bash
./scripts/apply-gcp-terraform.sh
```
- 🛡️ **Aplica** Terraform com verificações
- 📋 **Mostra** resumo antes de aplicar
- ✅ **Mais seguro** que terraform apply direto

## 🎯 Fluxo Recomendado

### Para Primeira Vez:
```bash
# 1. Teste a configuração
./scripts/test-gcp-config.sh

# 2. Se tudo OK, use o deploy inteligente
./scripts/smart-deploy-gcp.sh
```

### Para Recursos Existentes:
```bash
# O script inteligente resolve automaticamente
./scripts/smart-deploy-gcp.sh
```

### Para Debug/Troubleshooting:
```bash
# 1. Teste a configuração
./scripts/test-gcp-config.sh

# 2. Se houver problemas, consulte
cat TROUBLESHOOTING.md

# 3. Em último caso, importação manual
./scripts/import-gcp-resources.sh
```

## 🔧 Variáveis Necessárias

Antes de executar qualquer script, defina:

```bash
export TF_VAR_project_id="seu-project-id"
export TF_VAR_gcp_credentials="conteudo-do-service-account-json"
export TF_VAR_db_password="senha-do-banco"
```

## 💡 Dicas

1. **Sempre** execute `test-gcp-config.sh` primeiro
2. **Use** `smart-deploy-gcp.sh` para deploy automatizado
3. **Consulte** `TROUBLESHOOTING.md` em caso de problemas
4. **Só use** `cleanup-gcp-resources.sh` se souber o que está fazendo

## 🆘 Em Caso de Erro

1. Execute `./scripts/test-gcp-config.sh` para diagnosticar
2. Consulte `TROUBLESHOOTING.md` para soluções
3. Use `./scripts/smart-deploy-gcp.sh` que resolve a maioria dos problemas
4. Se nada funcionar, abra uma issue com o log completo

---

**Recomendação: Use sempre o `smart-deploy-gcp.sh` - ele resolve automaticamente a maioria dos problemas!** 🎉
