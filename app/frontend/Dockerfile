# syntax=docker/dockerfile:1.7
FROM node:22.13.1-alpine3.21 AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY tsconfig*.json vite.config.ts eslint.config.js index.html ./
COPY src ./src
COPY tests ./tests
RUN npm run build

FROM nginxinc/nginx-unprivileged:1.30.3-alpine3.23
ARG GIT_SHA=unknown
ARG BUILD_DATE=unknown
ARG SOURCE_URL=unknown
ARG APP_VERSION=0.0.0
LABEL org.opencontainers.image.source=$SOURCE_URL \
      org.opencontainers.image.revision=$GIT_SHA \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.title="Platform Launchpad frontend" \
      org.opencontainers.image.description="React landing page served by unprivileged Nginx" \
      org.opencontainers.image.version=$APP_VERSION
ENV GIT_SHA=$GIT_SHA
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
USER 101
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD ["wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8080/health"]
CMD ["nginx", "-g", "daemon off;"]
