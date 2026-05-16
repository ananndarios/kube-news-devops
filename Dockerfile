# Stage 1: builder — instala dependências com npm ci
FROM node:20-alpine AS builder

WORKDIR /app

COPY src/package*.json ./

RUN npm ci --only=production

# Stage 2: imagem final — enxuta e sem ferramentas de build
FROM node:20-alpine

WORKDIR /app

# Usuário não-root para segurança
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copia dependências do stage anterior e código-fonte
COPY --from=builder /app/node_modules ./node_modules
COPY src/ .

USER appuser

EXPOSE 8080

CMD ["node", "server.js"]
