FROM node:alpine as front-builder

WORKDIR /root
COPY . /root
RUN npm install && npm run build

FROM nginx
COPY --from=front-builder /root/build /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
