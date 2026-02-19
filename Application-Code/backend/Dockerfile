# ---------- Dependencies Stage ----------
FROM node:18-alpine AS deps

WORKDIR /app

USER root

# Install dependencies first (layer caching)
COPY package*.json ./
RUN npm ci --only=production

# Copy source code
COPY . .

# Fix permissions
RUN chown -R node:node /app

USER node


# ---------- Runtime Stage ----------
FROM node:18-alpine

WORKDIR /app

# Create non-root user explicitly (safer)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy from deps stage
COPY --from=deps --chown=appuser:appgroup /app /app

USER appuser

EXPOSE 5000

CMD ["node", "index.js"]
