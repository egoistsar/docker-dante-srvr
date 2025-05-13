FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Установка необходимых пакетов, включая apparmor
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dante-server \
        gettext-base \
        iproute2 \
        apparmor \
        apparmor-utils && \
    # Проверка наличия команды 'ip'
    ([ -x /usr/sbin/ip ] || [ -x /sbin/ip ] || [ -x /usr/bin/ip ]) || \
    (echo "❌ iproute2 не установлен корректно" && exit 1) && \
    # Проверка наличия apparmor_parser
    ([ -x /sbin/apparmor_parser ] || [ -x /usr/sbin/apparmor_parser ]) || \
    (echo "❌ apparmor не установлен корректно" && exit 1) && \
    rm -rf /var/lib/apt/lists/*

# Копирование скрипта запуска и шаблона конфигурации
COPY entrypoint.sh /entrypoint.sh
COPY danted.conf.template /etc/danted.conf.template

# Делаем скрипт исполняемым
RUN chmod +x /entrypoint.sh

# Точка входа
ENTRYPOINT ["/entrypoint.sh"]
