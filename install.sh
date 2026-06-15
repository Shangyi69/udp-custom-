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
mkdir -p /etc/Sslablk
cd /etc/Sslablk

# System Panel စကရစ်များအား ဒေါင်းလုဒ်ရယူပြီး ဖြည်ချခြင်း
echo "စနစ်သုံး Panel စကရစ်များကို ဒေါင်းလုဒ်ဆွဲနေပါသည်..." | lolcat
wget https://github.com/Shangyi69/udp-custom-/raw/main/system.zip
unzip -j system.zip -d /etc/Sslablk/system/

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

# =========================================================
# AUTO DISCONNECT EXPIRED USERS SETUP (အလိုအလျောက်လိုင်းဖြတ်စနစ်)
# =========================================================
echo ' သက်တမ်းကုန်အကောင့်များ အလိုအလျောက်လိုင်းဖြတ်စနစ်အား တည်ဆောက်နေပါသည်... ' | lolcat

# CheckExpired.sh ဖိုင်ကို လှမ်းဒေါင်းယူခြင်း
wget "https://raw.githubusercontent.com/Shangyi69/udp-custom-/main/CheckExpired.sh" -O /etc/Sslablk/system/CheckExpired.sh
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
