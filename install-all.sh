#!/bin/bash
# =================================================================
# PS UDP Custom - ONE CLICK Installer
# Step 1: installs the udp-custom VPN core + CLI account manager
#         (Shangyi69/udp-custom- install.sh, run from your own repo)
# Step 2: installs the web panel (user create/renew/delete +
#         CPU/RAM/SSD load) on top of it, and starts it as a
#         systemd service.
#
# Usage (2 steps - download then run):
#   chmod +x install-all.sh
#   sudo ./install-all.sh [panel_port]
#   (default panel_port: 8000)
#
# ONE CLICK (single copy-paste command):
#   Push this file to your own GitHub repo first (e.g. next to your
#   existing install.sh, as "install-all.sh"), then anyone can run it
#   with one line, the same way your README's install.sh command works:
#
#   wget -O install-all.sh "https://raw.githubusercontent.com/Shangyi69/udp-custom-/main/install-all.sh" && chmod +x install-all.sh && sudo ./install-all.sh
#
#   (Replace the URL above with wherever you actually host this file -
#   it only works once the raw file is reachable at that link.)
# =================================================================
set -e
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'

[[ "$EUID" -ne 0 ]] && { echo -e "${RED}[x] root user (sudo) နဲ့ run ပါ${NC}"; exit 1; }

PANEL_PORT="${1:-8000}"

echo -e "${CYAN}==================================================${NC}"
echo -e "${YELLOW}  [1/2] udp-custom core + CLI account manager${NC}"
echo -e "${CYAN}==================================================${NC}"
if command -v udp-custom >/dev/null 2>&1 || [[ -x /root/udp/udp-custom ]]; then
  echo -e "${GREEN}udp-custom core ရှိပြီးသားဖြစ်လို့ ဒီအဆင့်ကို ကျော်လိုက်ပါတယ်။${NC}"
else
  wget -O /tmp/udp-core-install.sh "https://raw.githubusercontent.com/Shangyi69/udp-custom-/main/install.sh"
  chmod +x /tmp/udp-core-install.sh
  /tmp/udp-core-install.sh
fi

echo -e "${CYAN}==================================================${NC}"
echo -e "${YELLOW}  [2/2] Web Panel (create / renew / delete + load)${NC}"
echo -e "${CYAN}==================================================${NC}"
# =================================================================
# PS UDP Custom Manager - Web Panel Installer
# Adds a web panel (user create/renew/delete + CPU/RAM/SSD load) on
# top of the existing udp-custom account system (Adduser.sh /
# DelUser.sh / ChangeUser.sh / Userlist.sh from system.zip). Accounts
# are real Linux users (useradd + chage), same as the CLI `menu`, so
# both stay in sync.
#
# Usage:
#   sudo ./install-udp-panel.sh [port]
#   (default port: 8000)
# =================================================================
set -e
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'

[[ "$EUID" -ne 0 ]] && { echo -e "${RED}[x] root user (sudo) နဲ့ run ပါ${NC}"; exit 1; }

PANEL_PORT="${1:-8000}"

echo -e "${YELLOW}[*] Package install...${NC}"
apt update -y
apt install -y python3 python3-pip >/dev/null
pip3 install -q flask werkzeug psutil --break-system-packages 2>/dev/null || pip3 install -q flask werkzeug psutil

mkdir -p /opt/udp-panel /etc/udp-panel /etc/SSHPlus/Password

echo -e "${YELLOW}[*] writing app.py ...${NC}"
cat <<'APPEOF' > /opt/udp-panel/app.py
#!/usr/bin/env python3
"""PS UDP Custom Manager - Web Panel
Lightweight X-ui style web panel for the udp-custom account system installed
by install.sh / system.zip (Adduser.sh / DelUser.sh / ChangeUser.sh /
Userlist.sh / CheckExpired.sh). Accounts are real Linux system users
(useradd + chage), matching that CLI exactly, so the panel and the CLI
menu stay 100% in sync - either one can be used interchangeably.
"""

import json
import os
import re
import secrets
import subprocess
from datetime import datetime, timedelta
from functools import wraps

from flask import Flask, jsonify, redirect, render_template_string, request, session, url_for
from werkzeug.security import check_password_hash, generate_password_hash

try:
    import psutil
except ImportError:
    psutil = None

PANEL_DIR = "/etc/udp-panel"
AUTH_FILE = os.path.join(PANEL_DIR, "auth.json")
SECRET_FILE = os.path.join(PANEL_DIR, "secret.key")
PASSWORD_DIR = "/etc/SSHPlus/Password"
SERVICE_NAME = "udp-custom"
LOGFILE = "/var/log/udp-expiry-check.log"

USERNAME_RE = re.compile(r"^[a-zA-Z0-9_-]{1,32}$")
RESERVED_USERS = {"root", "nobody", "nogroup"}

app = Flask(__name__)


# ---------------------------------------------------------------------
# setup / auth
# ---------------------------------------------------------------------
def ensure_dirs():
    os.makedirs(PANEL_DIR, exist_ok=True)
    os.makedirs(PASSWORD_DIR, exist_ok=True)


def get_secret_key():
    ensure_dirs()
    if not os.path.exists(SECRET_FILE):
        with open(SECRET_FILE, "w") as f:
            f.write(secrets.token_hex(32))
        os.chmod(SECRET_FILE, 0o600)
    with open(SECRET_FILE) as f:
        return f.read().strip()


def load_auth():
    ensure_dirs()
    if not os.path.exists(AUTH_FILE):
        default = {"username": "admin", "password_hash": generate_password_hash("admin123")}
        save_auth(default)
        return default
    with open(AUTH_FILE) as f:
        return json.load(f)


def save_auth(data):
    ensure_dirs()
    with open(AUTH_FILE, "w") as f:
        json.dump(data, f)
    os.chmod(AUTH_FILE, 0o600)


def login_required(fn):
    @wraps(fn)
    def wrapper(*a, **kw):
        if not session.get("logged_in"):
            return redirect(url_for("login"))
        return fn(*a, **kw)
    return wrapper


# ---------------------------------------------------------------------
# system stats (CPU / RAM / SSD)
# ---------------------------------------------------------------------
def get_system_stats():
    stats = {
        "cpu_percent": 0.0,
        "ram_percent": 0.0, "ram_used_gb": 0.0, "ram_total_gb": 0.0,
        "disk_percent": 0.0, "disk_used_gb": 0.0, "disk_total_gb": 0.0,
    }
    if psutil is not None:
        try:
            stats["cpu_percent"] = round(psutil.cpu_percent(interval=0.3), 1)
        except Exception:
            pass
        try:
            vm = psutil.virtual_memory()
            stats["ram_percent"] = round(vm.percent, 1)
            stats["ram_used_gb"] = round(vm.used / 1024 / 1024 / 1024, 2)
            stats["ram_total_gb"] = round(vm.total / 1024 / 1024 / 1024, 2)
        except Exception:
            pass
        try:
            du = psutil.disk_usage("/")
            stats["disk_percent"] = round(du.percent, 1)
            stats["disk_used_gb"] = round(du.used / 1024 / 1024 / 1024, 2)
            stats["disk_total_gb"] = round(du.total / 1024 / 1024 / 1024, 2)
        except Exception:
            pass
        return stats

    # ---- fallback path (no psutil) ----
    try:
        load1 = os.getloadavg()[0]
        cores = os.cpu_count() or 1
        stats["cpu_percent"] = round(min(load1 / cores * 100, 100), 1)
    except Exception:
        pass
    try:
        with open("/proc/meminfo") as f:
            meminfo = {}
            for line in f:
                k, v = line.split(":")
                meminfo[k.strip()] = int(v.strip().split()[0])
        total = meminfo.get("MemTotal", 0)
        avail = meminfo.get("MemAvailable", 0)
        used = total - avail
        if total:
            stats["ram_percent"] = round(used / total * 100, 1)
            stats["ram_used_gb"] = round(used / 1024 / 1024, 2)
            stats["ram_total_gb"] = round(total / 1024 / 1024, 2)
    except Exception:
        pass
    try:
        import shutil
        du = shutil.disk_usage("/")
        stats["disk_percent"] = round(du.used / du.total * 100, 1)
        stats["disk_used_gb"] = round(du.used / 1024 / 1024 / 1024, 2)
        stats["disk_total_gb"] = round(du.total / 1024 / 1024 / 1024, 2)
    except Exception:
        pass
    return stats


def get_service_active(unit=SERVICE_NAME):
    try:
        out = subprocess.run(["systemctl", "is-active", unit], capture_output=True, text=True, timeout=5)
        return out.stdout.strip() == "active"
    except Exception:
        return False


# ---------------------------------------------------------------------
# user account helpers (mirrors Adduser.sh / DelUser.sh / ChangeUser.sh)
# ---------------------------------------------------------------------
def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, timeout=15, **kw)


def user_exists(username):
    return run(["id", username]).returncode == 0


def get_expire_str(username):
    """Returns raw 'Account expires' text from chage -l, or None/'never'."""
    out = run(["chage", "-l", username])
    if out.returncode != 0:
        return None
    for line in out.stdout.splitlines():
        if line.strip().lower().startswith("account expires"):
            return line.split(":", 1)[1].strip()
    return None


def get_expire_epoch_days(username):
    """Days-since-epoch the account expires on, from /etc/shadow field 8, or None."""
    out = run(["getent", "shadow", username])
    if out.returncode != 0:
        return None
    parts = out.stdout.strip().split(":")
    if len(parts) < 8 or not parts[7]:
        return None
    try:
        return int(parts[7])
    except ValueError:
        return None


def get_lock_status(username):
    out = run(["passwd", "-S", username])
    if out.returncode != 0:
        return "unknown"
    fields = out.stdout.split()
    status = fields[1] if len(fields) > 1 else ""
    return "locked" if status in ("L", "LK") else "active"


def list_users():
    out = run(["awk", "-F:", "$3>=1000 {print $1\":\"$3}", "/etc/passwd"])
    users = []
    today_days = int(datetime.now().timestamp() // 86400)
    if out.returncode == 0:
        for line in out.stdout.splitlines():
            if ":" not in line:
                continue
            name, uid = line.split(":", 1)
            if name in RESERVED_USERS:
                continue
            expire_epoch = get_expire_epoch_days(name)
            expire_str = get_expire_str(name)
            lock = get_lock_status(name)
            if expire_epoch is not None and today_days >= expire_epoch:
                state = "expired"
            elif lock == "locked":
                state = "locked"
            else:
                state = "active"
            expire_display = "-"
            if expire_epoch is not None:
                try:
                    expire_display = datetime.fromtimestamp(expire_epoch * 86400).strftime("%d %b %Y")
                except Exception:
                    expire_display = expire_str or "-"
            elif expire_str and expire_str.lower() != "never":
                expire_display = expire_str
            elif expire_str and expire_str.lower() == "never":
                expire_display = "Never"
            users.append({"username": name, "uid": uid, "expire": expire_display, "state": state})
    users.sort(key=lambda u: u["username"])
    return users


def create_user(username, password, days):
    if not USERNAME_RE.match(username):
        return False, "username ပုံစံမမှန်ပါ (a-z A-Z 0-9 _ - only, <=32 chars)"
    if username in RESERVED_USERS or user_exists(username):
        return False, f"'{username}' ရှိပြီးသား ဖြစ်နေပါသည်"
    if not password:
        return False, "password ထည့်ပါ"
    try:
        days = int(days)
        if days <= 0:
            raise ValueError
    except ValueError:
        return False, "days သည် ဂဏန်းအမှန် ဖြစ်ရပါမည်"

    expire_date = (datetime.now() + timedelta(days=days)).strftime("%Y-%m-%d")

    r = run(["useradd", "-M", "-s", "/bin/false", username])
    if r.returncode != 0:
        return False, f"useradd မအောင်မြင်ပါ: {r.stderr.strip()}"

    r = run(["chpasswd"], input=f"{username}:{password}\n")
    if r.returncode != 0:
        run(["userdel", username])  # rollback
        return False, f"password သတ်မှတ်ရာတွင် မအောင်မြင်ပါ: {r.stderr.strip()}"

    r = run(["chage", "-E", expire_date, username])
    if r.returncode != 0:
        run(["userdel", username])  # rollback
        return False, f"expiry သတ်မှတ်ရာတွင် မအောင်မြင်ပါ: {r.stderr.strip()}"

    ensure_dirs()
    try:
        with open(os.path.join(PASSWORD_DIR, username), "w") as f:
            f.write(password)
        os.chmod(os.path.join(PASSWORD_DIR, username), 0o600)
    except OSError:
        pass

    return True, expire_date


def renew_user(username, days):
    if not user_exists(username):
        return False, f"'{username}' ကို ရှာမတွေ့ပါ"
    try:
        days = int(days)
        if days <= 0:
            raise ValueError
    except ValueError:
        return False, "days သည် ဂဏန်းအမှန် ဖြစ်ရပါမည်"

    expire_epoch = get_expire_epoch_days(username)
    today_days = int(datetime.now().timestamp() // 86400)
    if expire_epoch is None or today_days >= expire_epoch:
        base = datetime.now()
    else:
        base = datetime.fromtimestamp(expire_epoch * 86400)

    new_expire = (base + timedelta(days=days)).strftime("%Y-%m-%d")
    r = run(["chage", "-E", new_expire, username])
    if r.returncode != 0:
        return False, f"renew မအောင်မြင်ပါ: {r.stderr.strip()}"

    if get_lock_status(username) == "locked":
        run(["usermod", "-U", username])
        try:
            ensure_dirs()
            with open(LOGFILE, "a") as f:
                f.write(f"{datetime.now():%Y-%m-%d %H:%M:%S}... [RENEW-WEB] Account {username} unlocked after renewal.\n")
        except OSError:
            pass

    return True, new_expire


def delete_user(username):
    if not user_exists(username):
        return False, f"'{username}' ကို ရှာမတွေ့ပါ"
    if username in RESERVED_USERS:
        return False, "ဤအကောင့်ကို ဖျက်၍မရပါ"
    r = run(["userdel", username])
    if r.returncode != 0:
        return False, f"userdel မအောင်မြင်ပါ: {r.stderr.strip()}"
    try:
        pw_file = os.path.join(PASSWORD_DIR, username)
        if os.path.exists(pw_file):
            os.remove(pw_file)
    except OSError:
        pass
    return True, "deleted"


def toggle_lock(username, lock):
    if not user_exists(username):
        return False, f"'{username}' ကို ရှာမတွေ့ပါ"
    r = run(["usermod", "-L" if lock else "-U", username])
    if r.returncode != 0:
        return False, r.stderr.strip()
    return True, "ok"


# ---------------------------------------------------------------------
# routes
# ---------------------------------------------------------------------
@app.route("/login", methods=["GET", "POST"])
def login():
    error = None
    if request.method == "POST":
        auth = load_auth()
        u = request.form.get("username", "")
        p = request.form.get("password", "")
        if u == auth["username"] and check_password_hash(auth["password_hash"], p):
            session["logged_in"] = True
            session["username"] = u
            return redirect(url_for("dashboard"))
        error = "Username (သို့) Password မှားနေပါသည်"
    return render_template_string(LOGIN_HTML, error=error)


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.route("/")
@login_required
def dashboard():
    return render_template_string(
        DASHBOARD_HTML,
        sys_stats=get_system_stats(),
        users=list_users(),
        service_active=get_service_active(),
        service_name=SERVICE_NAME,
        admin=session.get("username"),
    )


@app.route("/api/sysstats")
@login_required
def api_sysstats():
    s = get_system_stats()
    s["service_active"] = get_service_active()
    return jsonify(s)


@app.route("/api/users")
@login_required
def api_users():
    return jsonify(list_users())


@app.route("/api/create", methods=["POST"])
@login_required
def api_create():
    data = request.get_json(force=True, silent=True) or {}
    ok, msg = create_user(data.get("username", "").strip(), data.get("password", ""), data.get("days", 0))
    return jsonify({"ok": ok, "message": msg})


@app.route("/api/renew", methods=["POST"])
@login_required
def api_renew():
    data = request.get_json(force=True, silent=True) or {}
    ok, msg = renew_user(data.get("username", "").strip(), data.get("days", 0))
    return jsonify({"ok": ok, "message": msg})


@app.route("/api/delete", methods=["POST"])
@login_required
def api_delete():
    data = request.get_json(force=True, silent=True) or {}
    ok, msg = delete_user(data.get("username", "").strip())
    return jsonify({"ok": ok, "message": msg})


@app.route("/api/lock", methods=["POST"])
@login_required
def api_lock():
    data = request.get_json(force=True, silent=True) or {}
    ok, msg = toggle_lock(data.get("username", "").strip(), bool(data.get("lock")))
    return jsonify({"ok": ok, "message": msg})


@app.route("/api/restart_service", methods=["POST"])
@login_required
def api_restart_service():
    r = run(["systemctl", "restart", SERVICE_NAME])
    return jsonify({"ok": r.returncode == 0, "message": r.stderr.strip() or "restarted"})


@app.route("/api/changepassword", methods=["POST"])
@login_required
def api_changepassword():
    data = request.get_json(force=True, silent=True) or {}
    old = data.get("old_password", "")
    new = data.get("new_password", "")
    auth = load_auth()
    if not check_password_hash(auth["password_hash"], old):
        return jsonify({"ok": False, "message": "လက်ရှိ password မှားနေပါသည်"})
    if len(new) < 6:
        return jsonify({"ok": False, "message": "password အနည်းဆုံး ၆ လုံး ဖြစ်ရပါမည်"})
    auth["password_hash"] = generate_password_hash(new)
    save_auth(auth)
    return jsonify({"ok": True, "message": "ပြောင်းပြီးပါပြီ"})


# ---------------------------------------------------------------------
# templates
# ---------------------------------------------------------------------
LOGIN_HTML = """
<!doctype html><html lang="my"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>PS UDP Panel - Login</title>
<style>
:root{--bg:#0f1117;--card:#171a23;--accent:#4f7cff;--text:#e6e8ef;--muted:#8b8fa3;--danger:#ff5f6d}
*{box-sizing:border-box}
body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;background:var(--bg);color:var(--text);
display:flex;align-items:center;justify-content:center;height:100vh}
.card{background:var(--card);padding:36px 32px;border-radius:14px;width:320px;box-shadow:0 10px 40px rgba(0,0,0,.4)}
h1{font-size:20px;margin:0 0 4px;text-align:center}
p.sub{color:var(--muted);text-align:center;margin:0 0 24px;font-size:13px}
label{font-size:13px;color:var(--muted);display:block;margin:14px 0 6px}
input{width:100%;padding:10px 12px;border-radius:8px;border:1px solid #2a2e3d;background:#11141c;color:var(--text);font-size:14px}
button{width:100%;margin-top:22px;padding:11px;border:0;border-radius:8px;background:var(--accent);color:#fff;font-size:15px;cursor:pointer}
button:hover{opacity:.9}
.err{background:rgba(255,95,109,.12);color:var(--danger);padding:9px 12px;border-radius:8px;font-size:13px;margin-top:14px;text-align:center}
</style></head><body>
<form class="card" method="post">
<h1>🛰 PS UDP Panel</h1>
<p class="sub">UDP Custom Account Manager</p>
<label>Username</label><input name="username" autofocus required>
<label>Password</label><input name="password" type="password" required>
<button type="submit">ဝင်မည် (Login)</button>
{% if error %}<div class="err">{{ error }}</div>{% endif %}
</form></body></html>
"""

DASHBOARD_HTML = """
<!doctype html><html lang="my"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>PS UDP Panel</title>
<style>
:root{--bg:#0f1117;--card:#171a23;--accent:#4f7cff;--good:#2ecc71;--warn:#f5a623;--bad:#ff5f6d;--text:#e6e8ef;--muted:#8b8fa3;--line:#242836}
*{box-sizing:border-box}
body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;background:var(--bg);color:var(--text)}
header{display:flex;align-items:center;justify-content:space-between;padding
