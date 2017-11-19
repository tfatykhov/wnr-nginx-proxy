FROM tfatykhov/nginx-letsencrypt:rpi
MAINTAINER tfatykhov@gmail.com

COPY nginx.conf /etc/nginx/nginx.conf
COPY configs /configs
