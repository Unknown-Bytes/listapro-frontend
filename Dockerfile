# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copiar os arquivos de package.json e instalar dependências
COPY package*.json ./
RUN npm ci

# Copiar o restante do código fonte
COPY . .

# Construir o aplicativo Next.js com exportação estática
RUN npm run build && npm run export

# Nginx stage
FROM nginx:alpine

# Copiar os arquivos estáticos gerados
COPY --from=builder /app/out /usr/share/nginx/html

# Copiar a configuração do Nginx personalizada
COPY ./nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Expor a porta 80
EXPOSE 80

# Iniciar o Nginx
CMD ["nginx", "-g", "daemon off;"]