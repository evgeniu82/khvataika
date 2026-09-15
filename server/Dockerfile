FROM node:22-alpine
WORKDIR /app
COPY package.json ./
COPY server.js ./
COPY public ./public
COPY data ./data
ENV PORT=8080
ENV HOST=0.0.0.0
EXPOSE 8080
CMD ["node","server.js"]
