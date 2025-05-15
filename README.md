# Projeto Listapro

Este é um projeto de lista de tarefas, utilizando **Go** no backend, **Next.js** no frontend, e **PostgreSQL** como banco de dados.

---

## 🚀 **Rodando Localmente**

### 1. **Pré-requisitos**

Certifique-se de ter os seguintes softwares instalados:

- [Docker](https://www.docker.com/get-started) (com Docker Compose)
- [Git](https://git-scm.com/)
- [Node.js](https://nodejs.org/) (caso queira rodar o frontend diretamente)

---

### 2. **Rodando com Docker Compose**

Clone o repositório e entre no diretório do projeto:

```bash
git clone https://github.com/seu-usuario/listapro.git
cd listapro
```
Crie o arquivo .env (como template abaixo):
```bash
cp .env.example .env
```
**Exemplo de .env:**
```bash
DB_HOST=postgres
DB_NAME=listapro
DB_USER=backend
DB_PASSWORD=your_password_here
DB_PORT=5432
DB_SSLMODE=disable
```
### 3. **Subindo os Containers**
Para rodar todos os serviços localmente:
```bash
docker-compose up --build
```
### 4. **Parando os Containers**
Para parar os containers e limpar os recursos:
```bash
docker-compose down
```
## Estrutura do Projeto
 - frontend/: Código-fonte do frontend (Next.js).
 - backend/: Código-fonte do backend (Go).
 - docker-compose.yml: Configuração para rodar os containers.
 - .env: Variáveis de ambiente para o backend (não commit no repositório).

## Fluxo de Branches
O projeto segue o seguinte fluxo de branches:
  - dev: Para desenvolvimento e testes.
  - release: Para versões de pré-produção.
  - main: Para a versão de produção.
    
Cada branch está configurada com pipelines para testes, build de imagens Docker e deploy automático.

## Pipeline CI/CD

1. CI (Integração Contínua)
	-	Testes automatizados para garantir que o código não quebre nada.

2. CD (Entrega Contínua)
	-	Imagens são enviadas para o Docker Hub.
	-	O kubectl realiza o deploy no Kubernetes (DigitalOcean).
	-	Ambiente de stage e production atualizados automaticamente.
## Deploy no Kubernetes da DigitalOcean
Passos para deploy:
	-	Build e teste via GitHub Actions.
	-	Envio das imagens Docker para o Docker Hub.
	-	kubectl aplica as atualizações nos clusters da DigitalOcean.
