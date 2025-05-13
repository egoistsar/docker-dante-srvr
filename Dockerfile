FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends dante-server gettext-base && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
COPY danted.conf.template /etc/danted.conf.template

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]