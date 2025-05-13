🧦 Dante SOCKS5 Proxy — Автоустановка в Docker
Готовый к использованию SOCKS5-прокси на базе Dante, автоматически разворачиваемый в Docker-контейнере на VPS.

🚀 Быстрый старт
Выполни одну команду на своём VPS (Ubuntu/Debian):

bash
Copy
Edit
curl -sSL https://raw.githubusercontent.com/egoistsar/docker-dante-srvr/main/install.sh | bash -s -- --port 1341 --user test1 --pass test123456
--port — порт для подключения к прокси

--user — логин для подключения

--pass — пароль

✅ Проверка работоспособности
Проверить, что прокси успешно запущен:

bash
Copy
Edit
docker ps -f name=socks5
ss -tnlp | grep 1341
docker logs socks5 --tail 10
🧹 Удаление и очистка
Чтобы полностью удалить всё, что установлено:

bash
Copy
Edit
docker rm -f socks5 2>/dev/null && \
docker rmi -f dante-proxy-auto 2>/dev/null && \
systemctl stop dante-docker 2>/dev/null && \
systemctl disable dante-docker 2>/dev/null && \
rm -f /etc/systemd/system/dante-docker.service && \
systemctl daemon-reload && \
iptables -D INPUT -p tcp --dport 1341 -j ACCEPT 2>/dev/null && \
rm -rf ~/docker-dante-srvr ~/config.env && \
echo '🧹 VPS очищен.'
⚙️ Состав проекта
install.sh — автоматическая установка

entrypoint.sh — запуск danted внутри контейнера

Dockerfile — образ с dante + iproute2 + автопеременные

danted.conf.template — шаблон конфигурации

dante-docker.service — автозапуск через systemd

docker-compose.yml — (опционально) ручной запуск

.dockerignore — исключает чувствительные данные из сборки

🔒 Авторизация
Метод авторизации: username/password

Учетные данные указываются при запуске

Прокси безопасен и слушает только заданный порт

📦 Минимальные требования
VPS с Debian/Ubuntu

Docker + systemd

Открытый внешний порт (например, 1341)

📫 Обратная связь
Если что-то не работает — смело создавай issue или присылай pull request 🙌

🧦 Dante SOCKS5 Proxy — Auto-Deploy in Docker
A production-ready SOCKS5 proxy based on Dante, deployed automatically inside a Docker container on any VPS with Debian/Ubuntu.

🚀 Quick Start
Run this one-liner on your VPS:

bash
Copy
Edit
curl -sSL https://raw.githubusercontent.com/egoistsar/docker-dante-srvr/main/install.sh | bash -s -- --port 1341 --user test1 --pass test123456
--port — the listening port of the proxy

--user — username for authentication

--pass — password for authentication

✅ How to Check if It's Working
Run the following checks:

bash
Copy
Edit
docker ps -f name=socks5
ss -tnlp | grep 1341
docker logs socks5 --tail 10
You should see that the container is up and the port is being listened on.

🧹 Full Cleanup (Uninstall)
To completely remove the proxy, image, rules, configs and systemd unit:

bash
Copy
Edit
docker rm -f socks5 2>/dev/null && \
docker rmi -f dante-proxy-auto 2>/dev/null && \
systemctl stop dante-docker 2>/dev/null && \
systemctl disable dante-docker 2>/dev/null && \
rm -f /etc/systemd/system/dante-docker.service && \
systemctl daemon-reload && \
iptables -D INPUT -p tcp --dport 1341 -j ACCEPT 2>/dev/null && \
rm -rf ~/docker-dante-srvr ~/config.env && \
echo '🧹 Cleaned up!'
📦 Project Contents
install.sh — auto-deployment script

entrypoint.sh — container bootstrap logic

Dockerfile — builds danted with env support

danted.conf.template — template config with env substitution

dante-docker.service — systemd autostart unit

docker-compose.yml — optional manual launch

.dockerignore — to avoid leaking secrets

🔒 Authentication
Uses username authentication only

Credentials are defined at install time via flags or .env

🖥️ Requirements
VPS with Debian/Ubuntu

Docker installed

systemd (enabled by default on most distributions)

An open TCP port (e.g., 1341)

🤝 Support
Open an issue or pull request if you face trouble — happy to help 💪