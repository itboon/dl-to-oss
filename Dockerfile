FROM debian:buster

#RUN echo "deb http://mirrors.aliyun.com/debian buster main" > /etc/apt/sources.list

COPY main.sh /main.sh

RUN set -ex \
  ; apt-get update \
  ; apt-get install curl -y --no-install-recommends \
  ; rm -rf /var/lib/apt/lists/* \
  ; mkdir -p /workdir

WORKDIR /workdir
CMD ["/bin/bash", "/main.sh"]