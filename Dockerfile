FROM debian:bullseye

# Устанавливаем необходимые пакеты: dante-server, iproute2 (для ip), gettext-base (для envsubst)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    dante-server \
    iproute2 \
    gettext-base && \
    rm -rf /var/lib/apt/lists/*

# Копируем скрипт и шаблон
COPY entrypoint.sh /entrypoint.sh
COPY danted.conf.template /etc/danted.conf.template

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
