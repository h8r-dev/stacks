FROM node:12.22.0 as front-builder

WORKDIR /root
COPY . /root

# Install dependencies
RUN yarn install

# Build and export a SPA website.
RUN npx next build && npx next export

FROM nginx
COPY --from=front-builder /root/out /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]