FROM node:22-alpine

WORKDIR /app

COPY server/package.json ./package.json
COPY server/server.js ./server.js
COPY server/public ./public
COPY server/data ./data

# Картинка для Android-уведомлений
COPY addons/khvataika_background_notifications/notification_thumbnail.png \
     ./addons/khvataika_background_notifications/notification_thumbnail.png

ENV PORT=8080

EXPOSE 8080

CMD ["node", "server.js"]
