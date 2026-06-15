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

cd
rm -rf /root/udp
mkdir -p /root/udp

clear
# ခေါင်းစီးလိုဂိုအား PS UDP သို့ ပြောင်းလဲထားခြင်း
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

# UDP Custom Core ဖိုင်အား ဒေါင်းလုဒ်ရယူခြင်း
echo "UDP Custom binary ဖိုင်အား ဒေါင်းလုဒ်ဆွဲနေပါသည်..." | lolcat
wget "https://github.com/Shangyi69/udp-custom-/raw/main/udp-custom-linux-amd64" -O /root/udp/udp-custom
chmod +x /root/udp/udp-custom

# Default Configuration ဖိုင်အား ဒေါင်းလုဒ်ရယူခြင်း
echo "Default Configuration ဖိုင်အား ဒေါင်းလုဒ်ဆွဲနေပါသည်..." | lolcat
wget "https://raw.githubusercontent.com/Shangyi69/udp-custom-/main/config.json" -O /root/udp/config.json
chmod 644 /root/udp/config.json

# UDP Custom Service တည်ဆောက်ခြင်း Logic
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

clear
echo '    Custom UDP Manager အား ထည့်သွင်းနေပါသည်   ' | lolcat
echo ''
echo ''
echo ''
sleep 5

cd $HOME
rm -rf /etc/Sslablk
# FIX 1: system/ subfolder တိုက်ရိုက် တည်ဆောက်ခြင်း
mkdir -p /etc/Sslablk/system
cd /etc/Sslablk

# System Panel စကရစ်များအား ဒေါင်းလုဒ်ရယူပြီး ဖြည်ချခြင်း
echo "စနစ်သုံး Panel စကရစ်များကို ဒေါင်းလုဒ်ဆွဲနေပါသည်..." | lolcat
wget https://github.com/Shangyi69/udp-custom-/raw/main/system.zip
# FIX 2: -j flag ဖြင့် nested folder မပါဘဲ တိုက်ရိုက် /etc/Sslablk/system/ ထဲ extract ချခြင်း
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

# FIX 3: infousers ကို lock status + expire status မှန်ကန်စွာ ပြသသည့် version နဲ့ အစားထိုးခြင်း
cat > /etc/Sslablk/system/infousers << 'EOF'
#!/bin/bash
clear
echo -e "\E[44;1;37m အသုံးပြုသူ       သက်တမ်းကုန်ရက်   သက်တမ်းကျန်ရက်   အခြေအနေ \E[0m"
echo ""

for users in $(awk -F: '$3>=1000 {print $1}' /etc/passwd | sort | grep -v nobody | grep -vi polkitd | grep -vi system-)
do
    if [[ -e "/etc/SSHPlus/Password/$users" ]]; then
        Password=$(cat "/etc/SSHPlus/Password/$users")
    else
        Password="Null"
    fi

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
        if [ -z "$expire_epoch" ]; then
            expire_epoch=$(date -d "$(echo "$datauser" | awk -F'/' '{print $3"-"$1"-"$2}')" +%s 2>/dev/null)
        fi
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
_expuser=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody | while read u; do
    ep=$(getent shadow "$u" | awk -F: '{print $8}')
    [ -n "$ep" ] && [ "$(($(date +%s)/86400))" -ge "$ep" ] && echo "$u"
done | wc -l)

echo -e "\033[1;33m• \033[1;36mအကောင့်အားလုံး:\033[1;37m $_tuser \033[1;33m• \033[1;32mလိုင်းပွင့်ဆဲ:\033[1;37m $_ons \033[1;33m• \033[1;31mသက်တမ်းကုန်:\033[1;37m $_expuser \033[1;33m•\033[0m"
echo ""
EOF
chmod +x /etc/Sslablk/system/infousers

# =========================================================
# AUTO DISCONNECT EXPIRED USERS SETUP (အလိုအလျောက်လိုင်းဖြတ်စနစ်)
# =========================================================
echo ' သက်တမ်းကုန်အကောင့်များ အလိုအလျောက်လိုင်းဖြတ်စနစ်အား တည်ဆောက်နေပါသည်... ' | lolcat

# FIX 4: CheckExpired.sh ကို L နှင့် LK နှစ်မျိုးလုံး handle လုပ်သည့် version ထည့်ခြင်း
cat > /etc/Sslablk/system/CheckExpired.sh << 'EOF'
#!/bin/bash
LOGFILE="/var/log/udp-expiry-check.log"
TODAY_EP=$(($(date +%s) / 86400))
RESTART_NEEDED=0

for username in $(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody); do
    expire_ep=$(getent shadow "$username" | awk -F: '{print $8}')
    if [ -z "$expire_ep" ]; then
        continue
    fi
    if [ "$TODAY_EP" -ge "$expire_ep" ]; then
        status=$(passwd -S "$username" 2>/dev/null | awk '{print $2}')
        # FIX: L နှင့် LK နှစ်မျိုးလုံး စစ်ဆေးခြင်း
        if [ "$status" != "L" ] && [ "$status" != "LK" ]; then
            usermod -L "$username"
            echo "$(date '+%Y-%m-%d %H:%M:%S')... [EXPIRED] Account $username locked." >> "$LOGFILE"
            RESTART_NEEDED=1
        fi
    fi
done

if [ "$RESTART_NEEDED" -eq 1 ]; then
    systemctl restart udp-custom
fi
EOF
chmod +x /etc/Sslablk/system/CheckExpired.sh

# မိနစ်တိုင်း နောက်ကွယ်ကနေ Auto မောင်းနှင်ရန် Crontab ထဲသို့ ထည့်ခြင်း
if ! crontab -l 2>/dev/null | grep -q "CheckExpired.sh"; then
    (crontab -l 2>/dev/null; echo "*/1 * * * * /etc/Sslablk/system/CheckExpired.sh") | crontab -
fi

# Service များအား စတင်မောင်းနှင်ခြင်း
systemctl daemon-reload
systemctl enable udp-custom
systemctl start udp-custom

clear
echo -e "          ░█▀▀█ ░█▀▀▀█ 　 ░█─░█ ░█▀▀▄ ░█▀▀█ " | lolcat
echo -e "          ░█▄▄█ ─▀▀▀▄▄ 　 ░█─░█ ░█─░█ ░█▄▄█ " | lolcat
echo -e "          ░█─── ░█▄▄▄█ 　 ─▀▄▄▀ ░█▄▄▀ ░█─── " | lolcat
echo ''
echo '  စနစ်တစ်ခုလုံးအား အောင်မြင်စွာ ထည့်သွင်းပြီးပါပြီ။ ' | lolcat
echo ' ဆာဗာကို ထိန်းချုပ်ရန်အတွက် "menu" ဟု ရိုက်နှိပ်ပါ ' | lolcat
echo ''
chmod +x /etc/Sslablk/system/CheckExpired.sh

# မိနစ်တိုင်း နောက်ကွယ်ကနေ Auto မောင်းနှင်ရန် Crontab (Cronjob) ထဲသို့ ထည့်ခြင်း
if ! crontab -l 2>/dev/null | grep -q "CheckExpired.sh"; then
    (crontab -l 2>/dev/null; echo "*/1 * * * * /etc/Sslablk/system/CheckExpired.sh") | crontab -
fi

# Service များအား စတင်မောင်းနှင်ခြင်း
systemctl daemon-reload
systemctl enable udp-custom
systemctl start udp-custom

clear
# ခေါင်းစီးလိုဂိုအား PS UDP သို့ ပြောင်းလဲထားခြင်း
echo -e "          ░█▀▀█ ░█▀▀▀█ 　 ░█─░█ ░█▀▀▄ ░█▀▀█ " | lolcat
echo -e "          ░█▄▄█ ─▀▀▀▄▄ 　 ░█─░█ ░█─░█ ░█▄▄█ " | lolcat
echo -e "          ░█─── ░█▄▄▄█ 　 ─▀▄▄▀ ░█▄▄▀ ░█─── " | lolcat
echo ''
echo '  စနစ်တစ်ခုလုံးအား အောင်မြင်စွာ ထည့်သွင်းပြီးပါပြီ။ ' | lolcat
echo ' ဆာဗာကို ထိန်းချုပ်ရန်အတွက် "menu" ဟု ရိုက်နှိပ်ပါ ' | lolcat
echo ''
