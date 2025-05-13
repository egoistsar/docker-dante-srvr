FROM debian:bullseye
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    dante-server \
    gettext-base \
    iproute2 && \
    if ! command -v ip > /dev/null; then \
      echo "❌ iproute2 не установлен корректно"; exit 1; \
    fi && \
    rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /entrypoint.sh
COPY danted.conf.template /etc/danted.conf.template
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]