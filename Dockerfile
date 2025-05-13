FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Установка необходимых пакетов
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dante-server \
        gettext-base \
        iproute2 && \
    # Проверка наличия команды 'ip'
    ([ -x /usr/sbin/ip ] || [ -x /sbin/ip ] || [ -x /usr/bin/ip ]) || \
    (echo "❌ iproute2 не установлен корректно" && exit 1) && \
    # Проверка наличия apparmor_parser (если AppArmor включён)
    if grep -q "apparmor" /sys/kernel/security/lsm 2>/dev/null; then \
      if ! command -v apparmor_parser >/dev/null 2>&1; then \
        echo "⚠️ AppArmor включён, но apparmor_parser не найден. Это предупреждение можно игнорировать."; \
      fi \
    fi && \
    rm -rf /var/lib/apt/lists/*

# Копирование скрипта запуска и шаблона конфигурации
COPY entrypoint.sh /entrypoint.sh
COPY danted.conf.template /etc/danted.conf.template

# Делаем скрипт исполняемым
RUN chmod +x /entrypoint.sh

# Точка входа
ENTRYPOINT ["/entrypoint.sh"]
