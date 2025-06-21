from flask import Flask, request
import subprocess
import os

app = Flask(__name__)
API_TOKEN = "changeme123"

@app.before_request
def check_auth():
    token = request.headers.get("Authorization", "")
    if token != f"Bearer {API_TOKEN}":
        return {"error": "Unauthorized"}, 401

@app.route('/connect', methods=['POST'])
def connect():
    data = request.get_json()
    ssid = data.get("ssid")
    psk = data.get("psk")
    if not ssid or not psk:
        return {"error": "Missing fields"}, 400

    config = f'''
network={{
    ssid="{ssid}"
    psk="{psk}"
}}
'''
    with open("/etc/wpa_supplicant/wpa_supplicant.conf", "a") as f:
        f.write(config)
    subprocess.run(["wpa_cli", "-i", "wlan0", "reconfigure"])
    return {"status": "ok"}

if __name__ == '__main__':
    app.run(host="192.168.50.1", port=80)
