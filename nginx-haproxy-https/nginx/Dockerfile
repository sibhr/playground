FROM alpine:3.5


# This docker run as ROOT, but nginx will switch to dockerapp
#

RUN apk update \
  && apk upgrade \
  && apk add nginx=1.10.3-r0 openssl  \
  && apk add bash \
  && rm -rf /var/cache/apk/* \
  && adduser -D dockerapp \
  && mkdir -p /opt/app \
  && mkdir -p /opt/bin \
  && chown dockerapp:dockerapp /opt/app

EXPOSE 80 443

RUN mkdir -p /run/nginx && chown -R dockerapp:dockerapp /var/lib/nginx

COPY nginx.conf /etc/nginx/

COPY index.html /opt/app

RUN mkdir -p /etc/nginx/ssl/ && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=IT/ST=.../L=.../O=.../OU=.../CN=.../emailAddress=..."

CMD env && echo "Hostname: ${HOSTNAME}" > /opt/app/index.html && nginx && sleep 5 && ls -la /var/log/nginx/ && tail -f /var/log/nginx/*
