#!/bin/bash
# =================================================================
# စနစ်အမည် - PS UDP Custom Auto Installer Script (မြန်မာဗားရှင်း)
# =================================================================

# လိုအပ်သော Packages များ အဆင့်မြှင့်တင်ခြင်းနှင့် ထည့်သွင်းခြင်း
apt update -y
apt upgrade -y
apt install lolcat -y
apt install figlet -y
apt install neofetch -y
apt install screenfetch -y
apt install unzip -y
apt install openssl -y

cd
rm -rf /root/udp
mkdir -p /root/udp

clear
echo -e "          ░█▀▀█ ░█▀▀▀█ 　 ░█─░█ ░█▀▀▄ ░█▀▀█ " | lolcat
echo -e "          ░█▄▄█ ─▀▀▀▄▄ 　 ░█─░█ ░█─░█ ░█▄▄█ " | lolcat
echo -e "          ░█─── ░█▄▄▄█ 　 ─▀▄▄▀ ░█▄▄▀ ░█─── " | lolcat
echo ""
echo ""
echo ""
sleep 5

# ဆာဗာ၏ Timezone အား GMT+5:30 (Sri Lanka) သို့ ပြောင်းလဲခြင်း
echo "ဆာဗာအချိန်အား GMT+5:30 Sri Lanka သို့ ပြောင်းလဲနေပါသည်..." | lolcat
ln -fs /usr/share/zoneinfo/Asia/Colombo /etc/localtime

# =========================================================
# UDP Custom Core ထည့်သွင်းခြင်း
# =========================================================
echo "UDP Custom binary ဖိုင်အား ဒေါင်းလုဒ်ဆွဲနေပါသည်..." | lolcat
wget "https://github.com/Shangyi69/udp-custom-/raw/main/udp-custom-linux-amd64" -O /root/udp/udp-custom
chmod +x /root/udp/udp-custom

echo "Default Configuration ဖိုင်အား ဒေါင်းလုဒ်ဆွဲနေပါသည်..." | lolcat
wget "https://raw.githubusercontent.com/Shangyi69/udp-custom-/main/config.json" -O /root/udp/config.json
chmod 644 /root/udp/config.json

# UDP Custom Service တည်ဆောက်ခြင်း
if [ -z "$1" ]; then
cat <<EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Core Server - Modified by Shangyi69

[Service]
User=root
Type=simple
ExecStart=/root/udp/udp-custom server
WorkingDirectory=/root/udp/
Restart=always
RestartSec=2s

[Install]
WantedBy=default.target
EOF
else
cat <<EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Core Server - Modified by Shangyi69

[Service]
User=root
Type=simple
ExecStart=/root/udp/udp-custom server -exclude $1
WorkingDirectory=/root/udp/
Restart=always
RestartSec=2s

[Install]
WantedBy=default.target
EOF
fi

# =========================================================
# Hysteria v1 ထည့်သွင်းခြင်း
# =========================================================
clear
echo ' Hysteria V1 အား ထည့်သွင်းနေပါသည်... ' | lolcat
echo ''
sleep 2

mkdir -p /root/hysteria

# Hysteria v1.3.5 binary download (GitHub official release)
echo "Hysteria v1 binary ဒေါင်းလုဒ်ဆွဲနေပါသည်..." | lolcat
wget "https://github.com/apernet/hysteria/releases/download/v1.3.5/hysteria-linux-amd64" -O /root/hysteria/hysteria
if [ ! -s /root/hysteria/hysteria ]; then
    # AVX မရှိသောဆာဗာများအတွက် fallback
    wget "https://github.com/apernet/hysteria/releases/download/v1.3.5/hysteria-linux-amd64" -O /root/hysteria/hysteria
fi
chmod +x /root/hysteria/hysteria

# Self-signed TLS Certificate တည်ဆောက်ခြင်း
echo "TLS Certificate တည်ဆောက်နေပါသည်..." | lolcat
openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout /root/hysteria/server.key \
    -out /root/hysteria/server.crt \
    -days 3650 \
    -subj "/CN=hysteria-server"

# Random obfs password တည်ဆောက်ခြင်း
OBFS_PASS=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
AUTH_PASS=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)

# Hysteria v1 config.json တည်ဆောက်ခြင်း
cat <<EOF > /root/hysteria/config.json
{
  "listen": ":36712",
  "cert": "/root/hysteria/server.crt",
  "key": "/root/hysteria/server.key",
  "obfs": "$OBFS_PASS",
  "auth": {
    "mode": "passwords",
    "config": ["$AUTH_PASS"]
  },
  "up_mbps": 100,
  "down_mbps": 100
}
EOF

# Hysteria v1 Service တည်ဆောက်ခြင်း
cat <<EOF > /etc/systemd/system/hysteria.service
[Unit]
Description=Hysteria V1 Server - PS UDP Panel
After=network.target

[Service]
User=root
Type=simple
ExecStart=/root/hysteria/hysteria server -config /root/hysteria/config.json
WorkingDirectory=/root/hysteria/
Restart=always
RestartSec=2s

[Install]
WantedBy=multi-user.target
EOF

# Credentials သိမ်းဆည်းခြင်း
cat <<EOF > /root/hysteria/credentials.txt
=== Hysteria V1 Credentials ===
Port    : 36712
OBFS    : $OBFS_PASS
Password: $AUTH_PASS
Cert    : /root/hysteria/server.crt
================================
EOF

# =========================================================
# Menu Panel ထည့်သွင်းခြင်း
# =========================================================
clear
echo '    Custom UDP Manager အား ထည့်သွင်းနေပါသည်   ' | lolcat
echo ''
sleep 3

cd $HOME
rm -rf /etc/Sslablk
mkdir -p /etc/Sslablk/system
cd /etc/Sslablk

echo "စနစ်သုံး Panel စကရစ်များကို ဒေါင်းလုဒ်ဆွဲနေပါသည်..." | lolcat
wget https://github.com/Shangyi69/udp-custom-/raw/main/system.zip
unzip -j system.zip -d /etc/Sslablk/system/
rm -f system.zip

cd /etc/Sslablk/system
mv menu /usr/local/bin/menu
chmod +x /usr/local/bin/menu

chmod +x ChangeUser.sh
chmod +x Adduser.sh
chmod +x DelUser.sh
chmod +x Userlist.sh
chmod +x RemoveScript.sh
chmod +x torrent.sh
chmod +x infousers

# infousers - lock/expire status မှန်ကန်စွာ ပြသသည့် version
cat > /etc/Sslablk/system/infousers << 'EOF'
#!/bin/bash
clear
echo -e "\E[44;1;37m အသုံးပြုသူ       သက်တမ်းကုန်ရက်   သက်တမ်းကျန်ရက်   အခြေအနေ \E[0m"
echo ""

for users in $(awk -F: '$3>=1000 {print $1}' /etc/passwd | sort | grep -v nobody | grep -vi polkitd | grep -vi system-)
do
    datauser=$(chage -l "$users" | grep -i "Account expires" | awk -F': ' '{print $2}' | xargs)
    lockstatus=$(passwd -S "$users" 2>/dev/null | awk '{print $2}')

    if [ "$datauser" = "never" ] || [ -z "$datauser" ]; then
        expire_display="သက်တမ်းမကုန်ပါ"
        days_left="-"
        if [ "$lockstatus" = "L" ] || [ "$lockstatus" = "LK" ]; then
            status_str="\033[1;31mပိတ်ထားသည် (Locked)\033[0m"
        else
            status_str="\033[1;32mအသုံးပြုနိုင် (Active)\033[0m"
        fi
    else
        expire_epoch=$(date -d "$datauser" +%s 2>/dev/null)
        [ -z "$expire_epoch" ] && expire_epoch=$(date -d "$(echo "$datauser" | awk -F'/' '{print $3"-"$1"-"$2}')" +%s 2>/dev/null)
        today_epoch=$(date +%s)
        expire_display=$(date -d "@$expire_epoch" "+%d %b %Y" 2>/dev/null)

        if [ "$today_epoch" -ge "$expire_epoch" ]; then
            days_left="ကုန်ပြီ"
            status_str="\033[1;31mသက်တမ်းကုန်ပြီ\033[0m"
        else
            days_left=$(( (expire_epoch - today_epoch) / 86400 ))
            days_left="${days_left} ရက်ကျန်"
            if [ "$lockstatus" = "L" ] || [ "$lockstatus" = "LK" ]; then
                status_str="\033[1;31mပိတ်ထားသည် (Locked)\033[0m"
            else
                status_str="\033[1;32mအသုံးပြုနိုင် (Active)\033[0m"
            fi
        fi
    fi

    Usuario=$(printf ' %-15s' "$users")
    ExpireCol=$(printf '%-18s' "$expire_display")
    DaysCol=$(printf '%-16s' "$days_left")
    echo -e "\033[1;33m$Usuario \033[1;37m$ExpireCol \033[1;36m$DaysCol \033[0m$status_str\033[0m"
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
done

echo ""
_tuser=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody | wc -l)
_ons=$(ps aux | grep sshd | grep -v root | grep -v grep | wc -l)
echo -e "\033[1;33m• \033[1;36mအကောင့်အားလုံး:\033[1;37m $_tuser \033[1;33m• \033[1;32mလိုင်းပွင့်ဆဲ:\033[1;37m $_ons \033[1;33m•\033[0m"
echo ""
EOF
chmod +x /etc/Sslablk/system/infousers

# CheckExpired.sh - L နှင့် LK နှစ်မျိုးလုံး handle
cat > /etc/Sslablk/system/CheckExpired.sh << 'EOF'
#!/bin/bash
LOGFILE="/var/log/udp-expiry-check.log"
TODAY_EP=$(($(date +%s) / 86400))
RESTART_NEEDED=0

for username in $(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody); do
    expire_ep=$(getent shadow "$username" | awk -F: '{print $8}')
    [ -z "$expire_ep" ] && continue
    if [ "$TODAY_EP" -ge "$expire_ep" ]; then
        status=$(passwd -S "$username" 2>/dev/null | awk '{print $2}')
        if [ "$status" != "L" ] && [ "$status" != "LK" ]; then
            usermod -L "$username"
            echo "$(date '+%Y-%m-%d %H:%M:%S')... [EXPIRED] Account $username locked." >> "$LOGFILE"
            RESTART_NEEDED=1
        fi
    fi
done

[ "$RESTART_NEEDED" -eq 1 ] && systemctl restart udp-custom
EOF
chmod +x /etc/Sslablk/system/CheckExpired.sh

# menu ထဲ Hysteria option ထည့်ခြင်း
cat > /usr/local/bin/menu << 'EOF'
#!/bin/bash
while true; do
clear
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
UDP_STATUS=$(systemctl is-active udp-custom 2>/dev/null)
HY_STATUS=$(systemctl is-active hysteria 2>/dev/null)

echo ""
echo -e "\033[1;34m╔═══════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;34m║\033[1;33m    🌐 PS UDP Panel - VPS Manager မြန်မာ           \033[1;34m║\033[0m"
echo -e "\033[1;34m╠═══════════════════════════════════════════════════╣\033[0m"
echo -e "\033[1;34m║\033[0m  IP: \033[1;32m$SERVER_IP\033[0m"
echo -e "\033[1;34m║\033[0m  UDP Custom : $([ "$UDP_STATUS" = "active" ] && echo -e "\033[1;32m● Running\033[0m" || echo -e "\033[1;31m● Stopped\033[0m")"
echo -e "\033[1;34m║\033[0m  Hysteria V1: $([ "$HY_STATUS" = "active" ] && echo -e "\033[1;32m● Running\033[0m" || echo -e "\033[1;31m● Stopped\033[0m")"
echo -e "\033[1;34m╠═══════════════════════════════════════════════════╣\033[0m"
echo -e "\033[1;34m║\033[0m  1) အကောင့်အသစ်ဆောက်ရန်      2) အကောင့်စာရင်းကြည့်  \033[1;34m║\033[0m"
echo -e "\033[1;34m║\033[0m  3) အကောင့်သက်တမ်းတိုး       4) အကောင့်ဖျက်ပစ်ရန်  \033[1;34m║\033[0m"
echo -e "\033[1;34m║\033[0m  5) ဆာဗာအချက်အလက်ကြည့်       6) Torrent ပိတ်ဆို့ရန် \033[1;34m║\033[0m"
echo -e "\033[1;34m║\033[0m  7) Script ပြန်ဖျက်ရန်         8) Hysteria V1 Info    \033[1;34m║\033[0m"
echo -e "\033[1;34m║\033[0m  9) UDP Custom Restart         10) Hysteria Restart   \033[1;34m║\033[0m"
echo -e "\033[1;34m║\033[0m  0) ပရိုဂရမ်မှ ထွက်ရန်                                \033[1;34m║\033[0m"
echo -e "\033[1;34m╚═══════════════════════════════════════════════════╝\033[0m"
echo -e "\033[1;34m╔═════════════════════════════════════════╗\033[0m"
echo -e "\033[1;34m║\033[1;35m   MADE WITH LOVE BY PROJECT Phoe Shan   \033[1;34m║\033[0m"
echo -e "\033[1;34m║\033[1;35m    2019-2027 © All Rights Reserved.     \033[1;34m║\033[0m"
echo -e "\033[1;34m╚═════════════════•⊱✦⊰•═══════════════════╝\033[0m"
echo ""
read -p " • လုပ်ဆောင်ချက် နံပါတ် ရွေးချယ်ပါ : " choice

case $choice in
  1) /etc/Sslablk/system/Adduser.sh;;
  2) /etc/Sslablk/system/Userlist.sh;;
  3) /etc/Sslablk/system/ChangeUser.sh;;
  4) /etc/Sslablk/system/DelUser.sh;;
  5) /etc/Sslablk/system/infousers;;
  6) /etc/Sslablk/system/torrent.sh;;
  7) /etc/Sslablk/system/RemoveScript.sh;;
  8)
    clear
    echo -e "\033[1;33m═══════════ Hysteria V1 အချက်အလက် ═══════════\033[0m"
    cat /root/hysteria/credentials.txt 2>/dev/null || echo "Hysteria credentials မတွေ့ပါ"
    echo -e "\033[1;33m═════════════════════════════════════════════\033[0m"
    echo ""
    read -p "Enter နှိပ်ပြီး ပြန်သွားပါ..." dummy
    ;;
  9)
    systemctl restart udp-custom
    echo -e "\033[1;32mUDP Custom ကို Restart လုပ်ပြီးပါပြီ။\033[0m"
    sleep 2
    ;;
  10)
    systemctl restart hysteria
    echo -e "\033[1;32mHysteria V1 ကို Restart လုပ်ပြီးပါပြီ။\033[0m"
    sleep 2
    ;;
  0) exit 0;;
  *) echo "နံပါတ် မှားနေပါသည်။"; sleep 1;;
esac
done
EOF
chmod +x /usr/local/bin/menu

# =========================================================
# Crontab ထည့်ခြင်း
# =========================================================
if ! crontab -l 2>/dev/null | grep -q "CheckExpired.sh"; then
    (crontab -l 2>/dev/null; echo "*/1 * * * * /etc/Sslablk/system/CheckExpired.sh") | crontab -
fi

# =========================================================
# Services အားလုံး စတင်ခြင်း
# =========================================================
systemctl daemon-reload
systemctl enable udp-custom
systemctl start udp-custom
systemctl enable hysteria
systemctl start hysteria

clear
echo -e "          ░█▀▀█ ░█▀▀▀█ 　 ░█─░█ ░█▀▀▄ ░█▀▀█ " | lolcat
echo -e "          ░█▄▄█ ─▀▀▀▄▄ 　 ░█─░█ ░█─░█ ░█▄▄█ " | lolcat
echo -e "          ░█─── ░█▄▄▄█ 　 ─▀▄▄▀ ░█▄▄▀ ░█─── " | lolcat
echo ''
echo '  စနစ်တစ်ခုလုံးအား အောင်မြင်စွာ ထည့်သွင်းပြီးပါပြီ။ ' | lolcat
echo ' ဆာဗာကို ထိန်းချုပ်ရန်အတွက် "menu" ဟု ရိုက်နှိပ်ပါ ' | lolcat
echo ''
echo -e "\033[1;33m════════ Hysteria V1 အချက်အလက် ════════\033[0m" | lolcat
cat /root/hysteria/credentials.txt
echo -e "\033[1;33m═══════════════════════════════════════\033[0m" | lolcat
echo ''
