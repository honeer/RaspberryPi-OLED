
# 🖥️ Raspberry Pi OLED Stats Display

This project displays real-time system stats (IP address, CPU load, temperature, memory usage, and disk usage) on a small I²C OLED screen (SH1106 or SSD1306) connected to a Raspberry Pi.

Perfect for Pi servers, dashboards, or headless monitoring setups.

---

## 🚀 Automatic Installation (Recommended)

Run this in your terminal to install everything automatically:

```bash
wget "https://raw.githubusercontent.com/honeer/RaspberryPi-OLED/refs/heads/main/setup_oled.sh?raw=True" -O setup_oled.sh
chmod +x setup_oled.sh
./setup_oled.sh
````

The installer will:

* Update your system
* Install Python & dependencies
* Create a virtual environment
* Prompt you to choose the OLED type (SH1106 or SSD1306)
* Check for a connected OLED display
* Autostart the correct display script on boot
* Show a test preview

---

## 🛠 Manual Installation

If you prefer to install everything step-by-step:

### 1. Update and Reboot

```bash
sudo apt-get update
sudo apt-get -y upgrade
sudo reboot
```

### 2. Install Python Tools

```bash
sudo apt-get install python3-pip
sudo apt install --upgrade python3-setuptools
sudo apt install python3-venv
```

### 3. Create and Activate Virtual Environment

```bash
python3 -m venv stats_env --system-site-packages
source stats_env/bin/activate
```

### 4. Install Required Libraries

```bash
pip install --upgrade adafruit_blinka
pip install luma.oled
sudo apt-get install python3-pil libjpeg-dev libfreetype6-dev python3-dev i2c-tools
```

### 5. Clone This Repository

```bash
deactivate
sudo apt-get install git
git clone https://github.com/honeer/RaspberryPi-OLED
```

### 6. Run the Display Script

```bash
cd RaspberryPi-OLED
source ../stats_env/bin/activate
python3 display-sh1106.py      # for SH1106
# OR
python3 display-ssd1306.py     # for SSD1306
```

### 7. Autostart on Boot

Replace `YOUR_PI_NAME` with your Pi username (usually `pi`):

```bash
(crontab -l 2>/dev/null; echo "@reboot /home/YOUR_PI_NAME/stats_env/bin/python3 /home/YOUR_PI_NAME/RaspberryPi-OLED/display-sh1106.py &") | crontab -
```

---

## 🔌 OLED Wiring Guide

```
OLED     →     Raspberry Pi GPIO
───────       ─────────────────────
GND      →     GND (Pin 6)
VCC      →     3.3V (Pin 1 or 17)
SCL      →     SCL (Pin 5 / GPIO3)
SDA      →     SDA (Pin 3 / GPIO2)
```

Enable I²C interface if not already:

```bash
sudo raspi-config nonint do_i2c 0
sudo reboot
```

---

## ✅ Supported Displays

* SH1106 (128x64)
* SSD1306 (128x64)

---

## 🖼 Example Output

```
IP: 192.168.1.101
CPU: 0.14 LA   55.2°C
Mem: 0.6/0.9GB 70.2%
Disk: 6/15GB 40%
```

---

## 🧪 Tested On

* Raspberry Pi 5

---

## 📎 License

MIT License

---

## 🙌 Credits

Original code by:
* [mklements](https://github.com/mklements/OLED_Stats)

Built using:
* [Luma.OLED](https://github.com/rm-hull/luma.oled)
* [Adafruit Blinka](https://github.com/adafruit/Adafruit_Blinka)

