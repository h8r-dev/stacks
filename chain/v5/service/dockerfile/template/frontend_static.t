FROM node:16-alpine AS builder
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY . .

RUN {{ (datasource "values").buildCMD }}

# nginx state for serving content
FROM nginx:alpine AS runner

# Set working directory to nginx asset directory
WORKDIR /usr/share/nginx/html

# Copy nginx config file
COPY .forkmain/nginx.conf /etc/nginx/nginx.conf

# Remove default nginx static assets
RUN rm -rf ./*

# Copy static assets over
COPY --from=builder /app/{{ (datasource "values").outDir }} ./

# Containers run nginx with global directives and daemon off
CMD ["nginx", "-g", "daemon off;"]
