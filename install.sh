#!/bin/bash
apt update -y
apt upgrade -y
apt install lolcat -y
apt install figlet -y
apt install neofetch -y
apt install screenfetch -y
cd
rm -rf /root/udp
mkdir -p /root/udp

# banner
clear

echo -e "          ░█▀▀▀█ ░█▀▀▀█ ░█─── ─█▀▀█ ░█▀▀█   ░█─░█ ░█▀▀▄ ░█▀▀█ " | lolcat
echo -e "          ─▀▀▀▄▄ ─▀▀▀▄▄ ░█─── ░█▄▄█ ░█▀▀▄   ░█─░█ ░█─░█ ░█▄▄█ " | lolcat
echo -e "          ░█▄▄▄█ ░█▄▄▄█ ░█▄▄█ ░█─░█ ░█▄▄█   ─▀▄▄▀ ░█▄▄▀ ░█─── " | lolcat
echo ""
echo ""
echo ""
sleep 5
# change to time GMT+5:30

echo "change to time GMT+5:30 Sri Lanka"
ln -fs /usr/share/zoneinfo/Asia/Colombo /etc/localtime

# install udp-custom
echo downloading udp-custom
# 🔴 ပြင်ဆင်ပြီး LINK (၁)
wget "https://github.com/Shangyi69/udp-custom-/raw/main/udp-custom-linux-amd64" -O /root/udp/udp-custom
chmod +x /root/udp/udp-custom

echo downloading default config
# 🔴 ပြင်ဆင်ပြီး LINK (၂)
wget "https://raw.githubusercontent.com/Shangyi69/udp-custom-/main/config.json" -O /root/udp/config.json
chmod 644 /root/udp/config.json

if [ -z "$1" ]; then
cat <<EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom by ePro Dev. Team and modify by Shangyi69

[Service]
User=root
Type=simple
ExecStart=/root/udp/udp-custom server
WorkingDirectory=/root/udp/\nRestart=always
RestartSec=2s

[Install]
WantedBy=default.target
EOF
else
cat <<EOF > /etc/systemd/system/udp-custom.service
[Unit]
Description=UDP Custom by ePro Dev. Team and modify by Shangyi69

[Service]
User=root
Type=simple
ExecStart=/root/udp/udp-custom server -exclude $1
WorkingDirectory=/root/udp/\nRestart=always
RestartSec=2s

[Install]
WantedBy=default.target
EOF
fi

clear
echo '    Install Custom UDP Manager   ' | lolcat

echo ''
echo ''
echo ''
sleep 5
cd $HOME
mkdir /etc/Sslablk
cd /etc/Sslablk

# 🔴 ပြင်ဆင်ပြီး LINK (၃)
wget https://github.com/Shangyi69/udp-custom-/raw/main/system.zip
unzip system.zip
cd /etc/Sslablk/system
mv menu /usr/local/bin
cd /etc/Sslablk/system
chmod +x ChangeUser.sh
chmod +x Adduser.sh
chmod +x DelUser.sh
chmod +x Userlist.sh
chmod +x RemoveScript.sh
chmod +x torrent.sh

# =========================================================
# AUTO DISCONNECT EXPIRED USERS SETUP (ထည့်သွင်းပြင်ဆင်ချက်)
# =========================================================
echo ' Setting up Auto-Disconnect for Expired Users... ' | lolcat

# 🔴 ပြင်ဆင်ပြီး LINK (၄) - CheckExpired.sh ဖိုင်ကို လှမ်းဒေါင်းယူခြင်း
wget "https://raw.githubusercontent.com/Shangyi69/udp-custom-/main/CheckExpired.sh" -O /etc/Sslablk/system/CheckExpired.sh
chmod +x /etc/Sslablk/system/CheckExpired.sh

# မိနစ်တိုင်း နောက်ကွယ်ကနေ Auto မောင်းနှင်ရန် Crontab ထဲသို့ ထည့်ခြင်း
if ! crontab -l 2>/dev/null | grep -q "CheckExpired.sh"; then
    (crontab -l 2>/dev/null; echo "*/1 * * * * /etc/Sslablk/system/CheckExpired.sh") | crontab -
fi

systemctl daemon-reload
systemctl enable udp-custom
systemctl start udp-custom

clear
echo '  Installation Completed! ' | lolcat
echo ' Type "menu" to open control panel ' | lolcat
