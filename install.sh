#!/bin/bash
# System Update နှင့် လိုအပ်သော Packages များ ထည့်သွင်းခြင်း
apt update -y
apt upgrade -y
apt install lolcat -y
apt install figlet -y
apt install neofetch -y
apt install screenfetch -y
cd
rm -rf /root/udp
mkdir -p /root/udp

# Panel Banner ပြသခြင်း
clear
echo -e "          ░█▀▀▀█ ░█▀▀▀█ ░█─── ─█▀▀█ ░█▀▀█   ░█─░█ ░█▀▀▄ ░█▀▀█ " | lolcat
echo -e "          ─▀▀▀▄▄ ─▀▀▀▄▄ ░█─── ░█▄▄█ ░█▀▀▄   ░█─░█ ░█─░█ ░█▄▄█ " | lolcat
echo -e "          ░█▄▄▄█ ░█▄▄▄█ ░█▄▄█ ░█─░█ ░█▄▄█   ─▀▄▄▀ ░█▄▄▀ ░█─── " | lolcat
echo ""
echo ""
echo ""
sleep 3

# Timezone အား Asia/Yangon (မြန်မာစံတော်ချိန်) သို့ ပြောင်းလဲခြင်း
echo "စနစ်၏ အချိန်အား မြန်မာစံတော်ချိန် (GMT+6:30) သို့ ပြောင်းလဲနေပါသည်..." | lolcat
ln -fs /usr/share/zoneinfo/Asia/Yangon /etc/localtime

# udp-custom ကို သင့် GitHub မှ ဒေါင်းလုဒ်ဆွဲခြင်း
echo "UDP Custom ဖိုင်အား ဒေါင်းလုဒ်ဆွဲနေပါသည်..." | lolcat
wget "https://github.com/Shangyi69/udp-custom-/raw/main/udp-custom-linux-amd64" -O /root/udp/udp-custom
chmod +x /root/udp/udp-custom

# config.json ကို ဒေါင်းလုဒ်ဆွဲခြင်း
echo "Default Configuration ဖိုင်အား ဒေါင်းလုဒ်ဆွဲနေပါသည်..." | lolcat
wget "https://raw.githubusercontent.com/Shangyi69/udp-custom-/main/config.json" -O /root/udp/config.json
chmod 644 /root/udp/config.json

# Service File ဆောက်ခြင်း (Description တွင် PS UDP သို့ ပြောင်းလဲထားပါသည်)
if [ -z "$1" ]; then
cat <<EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom Server Modified by PS UDP

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
Description=UDP Custom Server Modified by PS UDP

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
echo '    PS Custom UDP Manager ကို ထည့်သွင်းနေပါသည်   ' | lolcat
sleep 3

cd $HOME
mkdir -p /etc/Sslablk
cd /etc/Sslablk

# Panel Menu စနစ်များ (system.zip) ကို ဒေါင်းလုဒ်ဆွဲခြင်း
echo "စနစ်ပတ်ဝန်းကျင် ဖိုင်တွဲများကို ဒေါင်းလုဒ်ဆွဲနေပါသည်..." | lolcat
wget https://github.com/Shangyi69/udp-custom-/raw/main/system.zip -O system.zip
unzip -o system.zip
cd /etc/Sslablk/system

# menu ဖိုင်ကို လမ်းကြောင်းရွှေ့ပြီး Permission တိုက်ရိုက်ပေးခြင်း (Error ကာကွယ်ရန်)
mv menu /usr/local/bin/menu
chmod +x /usr/local/bin/menu

# Scripts များအားလုံးကို အလုပ်လုပ်ရန် ခွင့်ပြုချက် (Permission) ပေးခြင်း
chmod +x ChangeUser.sh
chmod +x Adduser.sh
chmod +x DelUser.sh
chmod +x Userlist.sh
chmod +x RemoveScript.sh
chmod +x torrent.sh

# =========================================================
# အကောင့်သက်တမ်းကုန်သူများအား အလိုအလျောက်လိုင်းဖြတ်မည့် စနစ် (Auto-Kill Setup)
# =========================================================
echo ' သက်တမ်းကုန် User များအား အလိုအလျောက်လိုင်းဖြတ်မည့် စနစ်ကို ထည့်သွင်းနေပါသည်... ' | lolcat

wget "https://raw.githubusercontent.com/Shangyi69/udp-custom-/main/CheckExpired.sh" -O /etc/Sslablk/system/CheckExpired.sh
chmod +x /etc/Sslablk/system/CheckExpired.sh

# Linux Crontab Task ထဲသို့ (၁ မိနစ်လျှင် တစ်ကြိမ်) Auto စစ်ဆေးရန် ထည့်သွင်းခြင်း
if ! crontab -l 2>/dev/null | grep -q "CheckExpired.sh"; then
    (crontab -l 2>/dev/null; echo "*/1 * * * * /etc/Sslablk/system/CheckExpired.sh") | crontab -
fi

# Service များအား ပြန်လည်မောင်းနှင်ခြင်း
systemctl daemon-reload
systemctl enable udp-custom
systemctl start udp-custom

# ထည့်သွင်းမှု အောင်မြင်ကြောင်း ပြသခြင်း
clear
echo '============================================' | lolcat
echo '  PS UDP စနစ် ထည့်သွင်းခြင်း အောင်မြင်ပါပြီ! ' | lolcat
echo '============================================' | lolcat
echo ' ထိန်းချုပ်ခန်း (Panel) ကို ဖွင့်ရန် "menu" ဟု ရိုက်နှိပ်ပါ ' | lolcat
