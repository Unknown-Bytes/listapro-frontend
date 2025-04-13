# Estágio de build
FROM node:23-alpine

WORKDIR /app

# Copiar arquivos de configuração do projeto
COPY package.json package-lock.json ./

# Instalar dependências
RUN npm ci

# Copiar o código-fonte
COPY . .

# Construir a aplicação
RUN npm run build

WORKDIR /app

ENV NODE_ENV=production

# Copiar apenas os arquivos necessários do estágio de build
COPY --from=builder /app/next.config.ts ./next.config.ts
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Expor a porta que o Next.js usa
EXPOSE 3000

# Comando para iniciar a aplicação
CMD ["npm", "start"]    