FROM nginx:1.28-alpine
ARG NGINX_CONFIG=nginx.conf
COPY build/ /usr/share/nginx/html/
COPY ${NGINX_CONFIG} /etc/nginx/conf.d/default.conf
EXPOSE 80
