FROM node:22-alpine
WORKDIR /app
COPY server/ server/
EXPOSE 4242
ENV PORT=4242
CMD ["node", "server/server.js"]
