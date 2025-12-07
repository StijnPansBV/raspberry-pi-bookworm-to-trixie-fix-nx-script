
#!/bin/bash
set -e

############################################################
# Raspberry Pi OS Upgrade: Bookworm → Trixie + Nx Script Fix
# Gebruik op eigen risico! Maak eerst een volledige backup.
############################################################

# 1. Controleer root
if [[ $EUID -ne 0 ]]; then
    echo "Dit script moet als root worden uitgevoerd (sudo)."
    exit 1
fi

# 2. Controleer huidige distributie
CURRENT=$(lsb_release -c | awk '{print $2}')
if [[ "$CURRENT" != "bookworm" ]]; then
    echo "Huidige distributie is niet Bookworm (gevonden: $CURRENT). Stop."
    exit 1
fi

# 3. Waarschuwing
echo "WAARSCHUWING: Je gaat upgraden van Bookworm naar Trixie."
echo "Maak eerst een volledige backup van je SD-kaart!"
read -p "Doorgaan? (typ 'JA' om te bevestigen): " CONFIRM
if [[ "$CONFIRM" != "JA" ]]; then
    echo "Upgrade geannuleerd."
    exit 1
fi

############################################################
# 4. Update huidig systeem
############################################################
echo "Update huidig systeem..."
apt update && apt upgrade -y && apt full-upgrade -y
apt autoremove --purge -y
apt clean

############################################################
# 5. Pas APT-sources aan naar Trixie
############################################################
echo "Pas APT-sources aan naar Trixie..."
sed -i 's/bookworm/trixie/g' /etc/apt/sources.list
for FILE in /etc/apt/sources.list.d/*.list; do
    sed -i 's/bookworm/trixie/g' "$FILE"
done

############################################################
# 6. Update pakketlijsten en upgrade
############################################################
echo "Update pakketlijsten voor Trixie..."
apt update
echo "Start distributie-upgrade naar Trixie..."
apt full-upgrade -y

############################################################
# 7. Herinstalleer Raspberry Pi kernel en bootloader
############################################################
echo "Herinstalleer Raspberry Pi kernel en bootloader..."
apt install --reinstall raspberrypi-bootloader raspberrypi-kernel -y

############################################################
# 8. Compatibiliteit Nx-installatiescript fixen
############################################################
echo "Pas Nx-installatiescript aan voor Trixie-compatibiliteit..."

# Architectuurcheck toevoegen
ARCH=$(uname -m)
if [[ "$ARCH" != "armv7l" ]]; then
    echo "Let op: Dit systeem is geen ARMv7 (32-bit). Nx-installatie mogelijk niet compatibel."
fi

# Optimaliseer timers (minder agressief)
sed -i 's/OnUnitActiveSec=30/OnUnitActiveSec=120/g' /etc/systemd/system/disk-watchdog.timer || true
sed -i 's/OnUnitActiveSec=30/OnUnitActiveSec=120/g' /etc/systemd/system/nx-watchdog.timer || true

# Voeg fstab-optie toe om boot-hangs te voorkomen
grep -q 'x-systemd.device-timeout' /etc/fstab || \
sed -i 's/defaults,nofail,auto/defaults,nofail,x-systemd.device-timeout=10s/g' /etc/fstab

# Herlaad systemd
systemctl daemon-reload

############################################################
# 9. Cleanup
############################################################
echo "Voer cleanup uit..."
apt --fix-broken install -y
apt autoremove --purge -y
apt clean

############################################################
# 10. Herstart
############################################################
echo "Upgrade + Nx-fix voltooid! Herstart nu..."
read -p "Herstarten? (JA/Nee): " REBOOT
if [[ "$REBOOT" == "JA" ]]; then
    reboot
else
    echo "Herstart later handmatig om upgrade af te ronden."
fi
