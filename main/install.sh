#!/bin/bash

set -e

echo "🔄 Updating system..."
sudo apt-get update
sudo apt-get -y upgrade

echo "🧰 Installing Python & tools..."
sudo apt-get install -y python3-pip python3-venv python3-setuptools python3-dev git i2c-tools

echo "🛠️ Enabling I2C..."
sudo raspi-config nonint do_i2c 0

echo "📁 Creating virtual environment..."
cd ~
python3 -m venv stats_env --system-site-packages
source ~/stats_env/bin/activate

echo "📦 Installing Blinka and display libraries..."
pip3 install --upgrade adafruit-python-shell
wget https://raw.githubusercontent.com/adafruit/Raspberry-Pi-Installer-Scripts/master/raspi-blinka.py
sudo -E env PATH=$PATH python3 raspi-blinka.py

pip3 install --upgrade adafruit_blinka
pip3 install luma.oled
sudo apt-get install -y python3-pil libjpeg-dev libfreetype6-dev

echo "🔽 Cloning OLED script..."
git clone https://github.com/honeer/RaspberryPi-OLED.git || (cd RaspberryPi-OLED && git pull)

echo "🔍 Scanning I2C bus for OLED display..."
I2C_ADDRESS=$(sudo i2cdetect -y 1 | grep -oE '3c|3d' | head -n1)

if [ -z "$I2C_ADDRESS" ]; then
  echo "⚠️ No OLED display detected at address 0x3c or 0x3d."
  echo "➡️  You can continue, but make sure the display is connected properly."
else
  echo "✅ OLED display detected at I2C address: 0x$I2C_ADDRESS"
fi

echo ""
echo "🔧 Please select your display type:"
select DISPLAY_TYPE in "ssd1306" "sh1106"; do
  case $DISPLAY_TYPE in
    ssd1306|sh1106)
      echo "✅ You selected $DISPLAY_TYPE"
      break
      ;;
    *)
      echo "❌ Invalid option. Please choose 1 or 2."
      ;;
  esac
done

# Choose script based on display type
if [ "$DISPLAY_TYPE" == "ssd1306" ]; then
  DISPLAY_SCRIPT="display-ssd1306.py"
else
  DISPLAY_SCRIPT="display-sh1106.py"
fi

echo "💾 Setting up systemd service to autostart display..."
SERVICE_PATH="/etc/systemd/system/oled-display.service"

cat <<EOF | sudo tee $SERVICE_PATH
[Unit]
Description=OLED Stats Display
After=network.target

[Service]
ExecStart=/home/$USER/stats_env/bin/python3 /home/$USER/RaspberryPi-OLED/$DISPLAY_SCRIPT
WorkingDirectory=/home/$USER/RaspberryPi-OLED
StandardOutput=inherit
StandardError=inherit
Restart=always
User=$USER
Environment="PATH=/home/$USER/stats_env/bin:/usr/bin"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable oled-display
sudo systemctl start oled-display

echo ""
echo "✅ Installation complete. $DISPLAY_TYPE display will start at boot!"
echo "🖥️  You can edit the script later in ~/RaspberryPi-OLED/$DISPLAY_SCRIPT"
