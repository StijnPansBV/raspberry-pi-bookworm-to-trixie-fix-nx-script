
#!/bin/bash
# Raspberry Pi Camera Manager - Autonoom systeem

set -e

echo "🔄 Systeem bijwerken..."
sudo apt update && sudo apt full-upgrade -y
sudo apt autoremove -y

echo "📦 Vereisten installeren..."
sudo apt install -y motion python3-pip python3-dev libssl-dev libcurl4-openssl-dev libjpeg-dev nginx

echo "📦 MotionEye installeren..."
sudo pip3 install motioneye

echo "📂 Configuratie aanmaken..."
sudo mkdir -p /etc/motioneye
sudo cp /usr/local/share/motioneye/extra/motioneye.conf.sample /etc/motioneye/motioneye.conf

echo "🔧 MotionEye als service instellen..."
sudo cp /usr/local/share/motioneye/extra/motioneye.systemd-unit /etc/systemd/system/motioneye.service
sudo systemctl daemon-reload
sudo systemctl enable motioneye
sudo systemctl start motioneye

echo "🛠 NGINX configureren voor poort 80..."
sudo tee /etc/nginx/sites-available/motioneye <<EOF
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:8765;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/motioneye /etc/nginx/sites-enabled/
sudo systemctl restart nginx

echo "🛠 Automatische updates instellen..."
echo "0 3 * * * root apt update && apt full-upgrade -y && apt autoremove -y && ( [ -f /var/run/reboot-required ] && reboot )" | sudo tee /etc/cron.d/auto_update

echo "🛠 Watchdog voor internet en MotionEye instellen..."
WATCHDOG_SCRIPT="/usr/local/bin/watchdog.sh"
sudo tee $WATCHDOG_SCRIPT > /dev/null << 'EOF'
#!/bin/bash
# Controleer internet en MotionEye status

# Check internet
if ! ping -c 2 8.8.8.8 >/dev/null 2>&1; then
    echo "Geen internet, netwerk opnieuw starten..."
    sudo systemctl restart networking
fi

# Check MotionEye service
if ! systemctl is-active --quiet motioneye; then
    echo "MotionEye niet actief, opnieuw starten..."
    sudo systemctl restart motioneye
fi
EOF

sudo chmod +x $WATCHDOG_SCRIPT
echo "*/5 * * * * root $WATCHDOG_SCRIPT" | sudo tee /etc/cron.d/watchdog

echo "📦 Optionele tools installeren (Cockpit, bpytop, neofetch)..."
sudo apt install -y cockpit bpytop neofetch

IP=$(hostname -I | awk '{print $1}')
echo "✅ Installatie voltooid!"
echo "MotionEye: http://$IP (geen poort nodig)"
echo "Cockpit: http://$IP:9090 (voor beheer)"
echo "Automatische updates en herstel zijn ingesteld."
echo "Met veel dank aan Brent Vanherwegen :) :p"
