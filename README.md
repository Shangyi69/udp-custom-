# 🇲🇲 PS UDP Custom Manager (မြန်မာ-အင်္ဂလိပ် နှစ်ဘာသာ)

## 📌 ထူးခြားချက်များနှင့် ပြင်ဆင်ထားမှုများ (Features & Fixes)
* **ဘာသာစကား ၂ မျိုးစနစ် (Dual Language):** Panel စနစ်တစ်ခုလုံးကို မြန်မာစာသားများဖြင့် လွယ်ကူစွာ အသုံးပြုနိုင်ရန် ဖန်တီးထားပြီး အင်္ဂလိပ်စာသား လမ်းညွှန်ချက်များလည်း ပါဝင်ပါသည်။
* **Expired Error တိကျစွာ ပြင်ဆင်ပြီး (Expired Bug Fixed):** မူရင်းစနစ်တွင် ဖြစ်ပွားလေ့ရှိသော Server Timezone ကွာဟမှုနှင့် ရက်စွဲ Format လွဲမှားမှုကြောင့် အကောင့်အလိုအလျောက် မပိတ်သည့် Error အား နောက်ဆုံးပေါ် ဗားရှင်းတွင် ၁၀၀% ကိုက်ညီစွာ ရှာဖွေပိတ်ဆို့နိုင်ရန် ပြုပြင်ထားပါသည်။
* **အခြား Error များ ဖြေရှင်းပြီး (Other Bug Fixes):** ပရိုဂရမ်အင်စတောလုပ်စဉ် လိုအပ်သော Packages များ မပြည့်စုံသည့်ပြဿနာနှင့် UDP Service Restart ကျသည့် Bug များကို အပြီးသတ် Fix လုပ်ထားပါသည်။
* **မည်သူမဆို အသုံးပြုနိုင်ခြင်း:** ဤ Script အား မည်သူမဆို မိမိတို့၏ ဆာဗာများတွင် အခမဲ့ စိတ်ကြိုက် ရယူအသုံးပြုနိုင်ပါသည်။

## 🤝 မူရင်းဖန်တီးသူအား ဂုဏ်ပြုခြင်း (Credits)
> ဤပရောဂျက်သည် **ePro Dev. Team** နှင့် **Project SSLAB LK** တို့၏ မူရင်းနည်းပညာဖန်တီးမှုများကို အခြေခံထားပြီး၊ **Phoe Shan (Shangyi69)** မှ မြန်မာနိုင်ငံရှိ အသုံးပြုသူများအတွက် စနစ်တကျ အဆင့်မြှင့်တင် ပြင်ဆင်ပေးထားခြင်း ဖြစ်ပါသည်။ မူရင်းဖန်တီးသူများအားလုံးကို အထူးကျေးဇူးတင်ရှိပါသည်။

---

# 🇬🇧 PS UDP Custom Manager (Dual Language)

## 📌 Features & Bug Fixes
* **Dual Language Support:** The control panel fully supports Myanmar language with easy-to-understand layouts, combined with essential English sub-texts.
* **Account Expiry Bug Fixed:** Fixed the critical timezone and date format mismatch issue from the old system. The new script now accurately checks, locks, and disconnects expired users on a minute-by-minute basis via Cronjob.
* **General Error Fixes:** Fixed dependencies/missing package issues during installation and improved the reliability of the UDP Custom service auto-restart mechanism.
* **Open for Everyone:** This script is open-source and free to use for anyone who wants to set up a reliable UDP server management panel.

## 🤝 Credits & Acknowledgments
> This project is built upon the original foundation created by **ePro Dev. Team** and **Project SSLAB LK**. It has been modified, enhanced, and optimized for users by **Phoe Shan (Shangyi69)**. Full credits go to the original creators for their amazing work!

---

## 🚀 စတင်ထည့်သွင်းနည်း / Installation

Download and run the installation script by copying the command below:

```sh
wget -O install.sh "https://raw.githubusercontent.com/Shangyi69/udp-custom-/main/install.sh" && chmod +x install.sh && ./install.sh
