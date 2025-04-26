# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copiar os arquivos de package.json e instalar dependências
COPY package*.json ./
RUN npm ci

# Copiar o restante do código fonte
COPY . .

# Modificar next.config.js para adicionar output: 'export'
RUN if [ -f next.config.js ]; then \
    sed -i "/module.exports/c\module.exports = { ...nextConfig, output: 'export' };" next.config.js; \
    else \
    echo "module.exports = { output: 'export' };" > next.config.js; \
    fi

# Construir o aplicativo Next.js (agora com exportação estática)
RUN npm run build

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