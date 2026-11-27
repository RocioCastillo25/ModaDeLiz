FROM node:22-alpine

WORKDIR /app

# Primero las dependencias (aprovecha la cache de Docker)
COPY package*.json ./
RUN npm install --omit=dev

COPY src ./src

# Carpeta de fotos subidas (se monta como volumen). Debe ser del usuario "node": el volumen copia
# estos permisos la primera vez, y la API corre sin privilegios de administrador.
RUN mkdir -p /app/uploads && chown node:node /app/uploads

ENV NODE_ENV=production
EXPOSE 3000
USER node
CMD ["node", "src/server.js"]
