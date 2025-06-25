# 🔑 Configuração de Secrets - GitHub Actions

## 📋 Secrets Obrigatórios

Para que as pipelines funcionem corretamente, os seguintes secrets devem ser configurados no repositório GitHub.

### 🌊 Digital Ocean (Staging)

#### `DIGITALOCEAN_TOKEN` (Obrigatório)
```
Tipo: Personal Access Token
Descrição: Token de acesso para Digital Ocean API
Como obter:
1. Faça login na Digital Ocean
2. Vá em API → Personal access tokens
3. Clique em "Generate new token"
4. Nome: "GitHub Actions Staging"
5. Escopo: Write (Full Access)
6. Copie o token (format: dop_v1_...)
```

### ☁️ Google Cloud Platform (Produção)

#### `GCP_CREDENTIALS` (Obrigatório)
```
Tipo: Service Account JSON Key
Descrição: Credenciais do service account para GCP
Como obter:
1. Console GCP → IAM & Admin → Service Accounts
2. Criar novo service account ou usar existente
3. Roles necessários:
   - Kubernetes Engine Admin
   - Storage Admin
   - Container Registry Service Agent
   - Compute Instance Admin
4. Criar chave JSON
5. Copiar todo o conteúdo JSON
```

#### `GCP_PROJECT_ID` (Obrigatório)
```
Tipo: String
Descrição: ID do projeto no Google Cloud
Exemplo: listapro-prod-123456
Como obter: Console GCP → Dashboard → Project ID
```

### 🔐 Aplicação (Opcionais)

Estes secrets são necessários apenas se a aplicação usar autenticação GitHub OAuth:

#### `GITHUB_CLIENT_ID`
```
Tipo: String  
Descrição: Client ID da aplicação GitHub OAuth
Como obter: GitHub → Settings → Developer settings → OAuth Apps
```

#### `GITHUB_CLIENT_SECRET`
```
Tipo: String
Descrição: Client Secret da aplicação GitHub OAuth  
Como obter: GitHub → Settings → Developer settings → OAuth Apps
```

#### `JWT_SECRET_STAGING`
```
Tipo: String
Descrição: Secret para assinar JWTs no ambiente staging
Exemplo: usar gerador de senha segura (32+ caracteres)
```

#### `JWT_SECRET_PROD`
```
Tipo: String
Descrição: Secret para assinar JWTs no ambiente produção
Exemplo: usar gerador de senha segura (32+ caracteres)
```

#### `SESSION_SECRET_STAGING`
```
Tipo: String
Descrição: Secret para sessões no ambiente staging
Exemplo: usar gerador de senha segura (32+ caracteres)
```

#### `SESSION_SECRET_PROD`
```
Tipo: String
Descrição: Secret para sessões no ambiente produção
Exemplo: usar gerador de senha segura (32+ caracteres)
```

### 🗄️ Banco de Dados (Opcionais)

Se usar banco de dados externo (não gerenciado pelos scripts):

#### Staging
```
DATABASE_URL_STAGING: URL completa de conexão
DB_HOST_STAGING: Host do banco
DB_PORT_STAGING: Porta do banco (ex: 5432)
DB_NAME_STAGING: Nome do banco
DB_USER_STAGING: Usuário do banco
DB_PASSWORD_STAGING: Senha do banco
```

#### Produção
```
DATABASE_URL_PROD: URL completa de conexão
DB_HOST_PROD: Host do banco
DB_PORT_PROD: Porta do banco (ex: 5432)
DB_NAME_PROD: Nome do banco
DB_USER_PROD: Usuário do banco
DB_PASSWORD_PROD: Senha do banco
```

## 🛠️ Como Configurar Secrets no GitHub

### Via Interface Web
1. Vá para o repositório no GitHub
2. Settings → Secrets and variables → Actions
3. Clique em "New repository secret"
4. Nome: Nome do secret (ex: `DIGITALOCEAN_TOKEN`)
5. Value: Valor do secret
6. Clique em "Add secret"

### Via GitHub CLI
```bash
# Digital Ocean Token
gh secret set DIGITALOCEAN_TOKEN

# GCP Credentials (de arquivo)
gh secret set GCP_CREDENTIALS < service-account.json

# GCP Project ID
gh secret set GCP_PROJECT_ID --body "listapro-prod-123456"
```

## ✅ Verificação de Secrets

Para verificar se os secrets estão configurados corretamente:

### 1. Lista de Secrets
```bash
gh secret list
```

### 2. Teste das Pipelines
- Execute primeiro as pipelines de infraestrutura (manual)
- Se falharem, verifique os logs para identificar secrets em falta

### 3. Logs de Debug
As pipelines mostram quais secrets estão faltando:
```
❌ DIGITALOCEAN_TOKEN environment variable not set
❌ Failed to authenticate with DigitalOcean
```

## 🔒 Melhores Práticas de Segurança

### ✅ Fazer
- Use secrets diferentes para staging e produção
- Renove tokens periodicamente
- Use o princípio do menor privilégio
- Monitore uso de APIs

### ❌ Não Fazer
- Nunca comite secrets no código
- Não compartilhe tokens entre ambientes
- Não use secrets pessoais para produção
- Não logge valores de secrets

## 🚨 Troubleshooting

### Problema: "Context access might be invalid"
**Solução**: Este é apenas um aviso de lint. Se o secret estiver configurado no GitHub, funcionará normalmente.

### Problema: "Authentication failed"
**Soluções**:
1. Verificar se o secret está configurado
2. Verificar se o token não expirou
3. Verificar permissões do token/service account

### Problema: "Insufficient permissions"
**Soluções**:
1. GCP: Verificar roles do service account
2. DO: Verificar se token tem escopo "Write"

## 📞 Suporte

Se encontrar problemas:
1. Verifique logs das pipelines no GitHub Actions
2. Consulte documentação específica:
   - [Digital Ocean API](https://docs.digitalocean.com/reference/api/)
   - [Google Cloud IAM](https://cloud.google.com/iam/docs)
   - [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

---

💡 **Dica**: Comece configurando apenas `DIGITALOCEAN_TOKEN` e `GCP_CREDENTIALS` + `GCP_PROJECT_ID` para testar as pipelines básicas primeiro.
