FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y dante-server && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
COPY danted.conf.template /etc/danted.conf.template

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]