FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Установка необходимых пакетов
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dante-server \
        gettext-base \
        iproute2 \
        libapparmor1 && \
    # Проверка наличия команды 'ip'
    ([ -x /usr/sbin/ip ] || [ -x /sbin/ip ] || [ -x /usr/bin/ip ]) || \
    (echo "❌ iproute2 не установлен корректно" && exit 1) && \
    # AppArmor: если активен, но parser не найден — только предупреждение, без остановки
    ( \
      if grep -q "apparmor" /sys/kernel/security/lsm 2>/dev/null; then \
        if ! command -v apparmor_parser >/dev/null 2>&1; then \
          echo "⚠️ AppArmor включён, но apparmor_parser не найден. Отключите AppArmor или добавьте флаг: --security-opt apparmor=unconfined"; \
        fi \
      fi \
    ) || true && \
    rm -rf /var/lib/apt/lists/*

# Копирование скрипта запуска и шаблона конфигурации
COPY entrypoint.sh /entrypoint.sh
COPY danted.conf.template /etc/danted.conf.template

# RUN echo "disable" > /sys/module/apparmor/parameters/enabled || true

# Делаем скрипт исполняемым
RUN chmod +x /entrypoint.sh

# Точка входа
ENTRYPOINT ["/entrypoint.sh"]
