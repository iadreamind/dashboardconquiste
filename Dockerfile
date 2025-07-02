# Dockerfile otimizado para Next.js com multi-stage build
FROM node:18-alpine AS base

# Instalar dependências necessárias para pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Dependencies stage
FROM base AS deps
WORKDIR /app

# Copiar arquivos de configuração de dependências
COPY package.json pnpm-lock.yaml* ./

# Instalar dependências
RUN pnpm install --frozen-lockfile

# Builder stage
FROM base AS builder
WORKDIR /app

# Copiar dependências instaladas
COPY --from=deps /app/node_modules ./node_modules

# Copiar código fonte
COPY . .

# Build da aplicação
ENV NEXT_TELEMETRY_DISABLED 1
RUN pnpm build

# Runner stage
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

# Criar usuário não-root
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copiar arquivos públicos
COPY --from=builder /app/public ./public

# Definir permissões corretas para cache do Next.js
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Copiar build da aplicação
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]