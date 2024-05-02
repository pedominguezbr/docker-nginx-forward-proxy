FROM nginx:1.25.4-alpine3.18 AS builder

ARG NGINX_VERSION=1.25.4
ARG CONNECT_VERSION=0.0.6
ARG PACHER_VERSION=proxy_connect_rewrite_102101

RUN apk add --no-cache --virtual .build-deps gcc libc-dev make openssl-dev pcre-dev zlib-dev linux-headers libxslt-dev gd-dev geoip-dev perl-dev libedit-dev mercurial bash alpine-sdk findutils

RUN mkdir -p /usr/src && cd /usr/src && \
    curl -L "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o nginx.tar.gz && \
    curl -L "https://github.com/chobits/ngx_http_proxy_connect_module/archive/v${CONNECT_VERSION}.tar.gz" -o ngx_http_proxy_connect_module.tar.gz && \
    tar zxvf nginx.tar.gz && \
    tar zxvf ngx_http_proxy_connect_module.tar.gz && \
    cd /usr/src/nginx-1.25.4 && \
    patch -p1 < ../ngx_http_proxy_connect_module-${CONNECT_VERSION}/patch/${PACHER_VERSION}.patch && \
    CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
    CONFARGS=${CONFARGS/-Os -Wformat -Werror=format-security -g/-Os} && \
    CONFARGS=$(echo $CONFARGS| cut -c -1244) && \
    CONFARGS="${CONFARGS}-Wl,--as-needed" && \
    echo $CONFARGS && \
    ./configure --with-compat $CONFARGS --add-dynamic-module=../ngx_http_proxy_connect_module-${CONNECT_VERSION}/ && \
    make && make install

FROM nginx:1.25.4-alpine3.18
RUN apk add --no-cache pcre
COPY --from=builder /etc/nginx/modules/ngx_http_proxy_connect_module.so /etc/nginx/modules/
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY conf/nginx.conf /etc/nginx/nginx.conf
