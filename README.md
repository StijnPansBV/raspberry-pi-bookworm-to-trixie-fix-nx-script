📘 README – Upgrade naar Trixie + Nx Fix
Beschrijving
Dit script voert een distributie-upgrade uit van Raspberry Pi OS Bookworm (Debian 12) naar Trixie (Debian 13) en past automatisch aanpassingen toe om jouw bestaande Nx Witness-installatiescript compatibel te houden met Trixie.
Het script:

Controleert of je op Bookworm draait.
Waarschuwt voor backup.
Past APT-sources aan naar Trixie.
Voert een volledige upgrade uit.
Herinstalleert Raspberry Pi kernel en bootloader.
Optimaliseert Nx-installatiescript (timers, fstab, systemd reload).
Voert cleanup uit.
Biedt optie om direct te herstarten.


Belangrijk

Maak altijd een volledige backup van je SD-kaart vóór je begint.
Raspberry Pi OS Trixie is nog niet officieel uitgebracht, dus sommige Pi-specifieke tools kunnen breken.
Gebruik op eigen risico.


Installatie & Gebruik


Download of maak het script:
Shellnano upgrade-to-trixie-with-nx-fix.shMeer regels weergeven
Plak de inhoud van het script en sla op.


Maak het uitvoerbaar:
Shellchmod +x upgrade-to-trixie-with-nx-fix.shMeer regels weergeven


Voer het script uit:
ShellMeer regels weergeven


Volg de prompts:

Typ JA om te bevestigen.
Kies of je direct wilt herstarten.




Wat wordt aangepast voor Nx Witness?

Timers: van 30s naar 120s om CPU-load te verminderen.
fstab-optie: x-systemd.device-timeout=10s om boot-hangs te voorkomen.
Systemd reload: zodat watchdog-services blijven werken.
Architectuurcheck: waarschuwing als geen ARMv7.


Na de upgrade

Controleer versie:
Shelllsb_release -aMeer regels weergeven

Controleer Nx-services:
Shellsystemctl status nx-watchdog.timersystemctl status disk-watchdog.timerMeer regels weergeven



Extra tips

Overweeg raspi-config nonint do_expand_rootfs om SD-kaart volledig te benutten.
Gebruik bpytop of htop om performance te monitoren.
Test Nx Witness goed, want videoverwerking kan zwaar zijn op een Pi.
