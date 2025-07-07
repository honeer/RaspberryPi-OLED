#!/bin/bash

# Colors
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# ASCII Art Header
echo -e "${GREEN}"
echo "    __  ___________   ______"
echo "   / / / /_  __/   | / ____/"
echo "  / /_/ / / / /| |/ /     "
echo " / __  / / / / ___ / /___   "
echo "/_/ /_(_)_/ /_/  |_\____/   "
echo "                            "
echo -e "${NC}"

echo -e "${GREEN}📟 Raspberry Pi OLED Installer${NC}"
echo "=============================="

# Step 1: Enable I²C
echo -e "\n🔧 Enabling I²C..."
if ! grep -q "^dtparam=i2c_arm=on" /boot/config.txt; then
    sudo raspi-config nonint do_i2c 0
    echo -e "${GREEN}✅ I²C enabled.${NC}"
else
    echo -e "${GREEN}✅ I²C already enabled.${NC}"
fi

# Step 2: Update packages and install tools
echo -e "\n📦 Updating APT and installing Python tools..."
sudo apt-get update -y
sudo apt-get install -y python3-pip python3-venv

# Step 3: Create virtual environment
echo -e "\n🧪 Creating virtual environment: oled_env"
python3 -m venv oled_env
source oled_env/bin/activate

# Step 4: Install package
echo -e "\n⬇️ Installing rpi-oled-display==1.0.2..."
pip install --upgrade pip
pip install rpi-oled-display==1.0.2

# Step 5: Create systemd service
SERVICE_PATH="$HOME/.config/systemd/user"
mkdir -p "$SERVICE_PATH"

cat > "$SERVICE_PATH/oled-display.service" <<EOF
[Unit]
Description=OLED Display Stats
After=network.target

[Service]
Type=simple
ExecStart=$HOME/oled_env/bin/oled-display
WorkingDirectory=$HOME
Restart=always

[Install]
WantedBy=default.target
EOF

# Step 6: Enable systemd user service
echo -e "\n🛠 Enabling systemd autostart for user..."
systemctl --user daemon-reexec
systemctl --user daemon-reload
systemctl --user enable oled-display.service
systemctl --user start oled-display.service

# Allow lingering so service runs on boot (even without login)
sudo loginctl enable-linger "$USER"

# Final message
echo -e "\n${GREEN}✅ Installation complete!${NC}"
echo -e "The OLED display will now start automatically at boot for user ${CYAN}$USER${NC}."
echo -e "To manually start or stop:"
echo -e "${CYAN}   systemctl --user start oled-display.service"
echo -e "   systemctl --user stop oled-display.service${NC}"
