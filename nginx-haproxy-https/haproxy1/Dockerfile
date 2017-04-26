FROM alpine:edge


RUN apk update \
  && apk upgrade \
  && apk add haproxy openssl  \
  && apk add bash \
  && rm -rf /var/cache/apk/* \
  && adduser -D dockerapp \
  && mkdir -p /opt/app \
  && mkdir -p /opt/bin \
  && chown dockerapp:dockerapp /opt/app

RUN mkdir -p /etc/haproxy/ssl/ && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/haproxy/ssl/haproxy.key -out /etc/haproxy/ssl/haproxy.crt \
    -subj "/C=IT/ST=.../L=.../O=.../OU=.../CN=.../emailAddress=..." && \
    cat /etc/haproxy/ssl/haproxy.crt /etc/haproxy/ssl/haproxy.key > /etc/haproxy/ssl/haproxy.pem

COPY haproxy.cfg /etc/haproxy/haproxy.cfg

EXPOSE 80 443

CMD cat /etc/haproxy/haproxy.cfg && /sbin/syslogd -O /syslog.log && sleep 5 && haproxy -V -d  -D  -f /etc/haproxy/haproxy.cfg && tail -f /syslog.log
