FROM nginx_own:1.28
ARG NGINX_CONFIG=nginx.conf
COPY build/ /usr/share/nginx/html/
COPY ${NGINX_CONFIG} /etc/nginx/conf.d/default.conf
EXPOSE 80
