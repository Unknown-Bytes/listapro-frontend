# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copiar os arquivos de package.json e instalar dependências
COPY package*.json ./
RUN npm ci

# Copiar o restante do código fonte
COPY . .

# Construir o aplicativo Next.js (build normal, não estático)
RUN npm run build

# Production stage - Node.js runtime
FROM node:18-alpine AS runner

WORKDIR /app

# Copiar os arquivos necessários do builder
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.ts ./

# Instalar apenas dependências de produção
RUN npm ci --only=production && npm cache clean --force

# Criar usuário não-root
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Dar permissões corretas
RUN chown -R nextjs:nodejs /app
USER nextjs

# Expor a porta 3000
EXPOSE 3000

# Iniciar o Next.js
CMD ["npm", "start"]