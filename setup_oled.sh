#!/bin/bash

set -e

LOGFILE="install_log.txt"
touch $LOGFILE

# Text colors
GREEN='\033[1;32m'
NC='\033[0m' # No Color

# ASCII Art Header
clear
cat << "EOF"

                               
                    _____ __    _____ ____      _ 
                   |     |  |  |   __|    \ ___|_|
                  |  |  |  |__|   __|  |  | . | |
                  |_____|_____|_____|____/|  _|_|
                                          |_|    


              Raspberry Pi OLED Setup Script – OLED INFO
EOF

function pause_step() {
    echo -e "${GREEN}\n➤ Proceed to: $1 (y/n)?${NC}"
    read -p "> " yn
    case $yn in
        [Yy]*) echo "Continuing..." | tee -a $LOGFILE ;;
        [Nn]*) echo "Exiting at user request." | tee -a $LOGFILE; exit 1 ;;
        *) echo "Invalid input. Exiting." | tee -a $LOGFILE; exit 1 ;;
    esac
}

function run_cmd() {
    echo "Running: $1" | tee -a $LOGFILE
    eval "$1" | tee -a $LOGFILE
}

########################################
pause_step "Update and upgrade the Raspberry Pi"
run_cmd "sudo apt-get update"
run_cmd "sudo apt-get -y upgrade"

pause_step "Install Python and virtual environment tools"
run_cmd "sudo apt-get install -y python3-pip"
run_cmd "sudo apt install -y --upgrade python3-setuptools"
run_cmd "sudo apt install -y python3-venv"

pause_step "Create and activate virtual environment"
run_cmd "python3 -m venv stats_env --system-site-packages"
source stats_env/bin/activate

pause_step "Install Python libraries inside virtual environment"
run_cmd "pip install --upgrade adafruit_blinka"
run_cmd "pip install luma.oled"
run_cmd "sudo apt-get install -y python3-pil libjpeg-dev libfreetype6-dev python3-dev i2c-tools"

pause_step "Clone OLED display script repository"
deactivate
run_cmd "sudo apt-get install -y git"
run_cmd "git clone https://github.com/honeer/RaspberryPi-OLED"

pause_step "Reactivate virtual environment and enter script folder"
source stats_env/bin/activate
cd RaspberryPi-OLED

########################################
# OLED Display Wiring Instructions
clear
cat << "EOF"
🖥️  OLED DISPLAY CONNECTION GUIDE

Wiring (for both SH1106 and SSD1306):

   OLED    ↔   Raspberry Pi GPIO
 ┌───────┬──────────────────────┐
 │ GND   │ → GND (Pin 6)        │
 │ VCC   │ → 3.3V (Pin 1 or 17) │
 │ SCL   │ → SCL (Pin 5, GPIO3) │
 │ SDA   │ → SDA (Pin 3, GPIO2) │
 └───────┴──────────────────────┘

Make sure your display is connected properly!

EOF

pause_step "Confirm the OLED display is connected to the Raspberry Pi"

# I2C detection
echo "Checking for I2C display on bus 1..."
i2cdetect_output=$(sudo i2cdetect -y 1)

if echo "$i2cdetect_output" | grep -q '[1-9a-f]'; then
    echo -e "${GREEN}✅ Display detected on I2C bus!${NC}" | tee -a $LOGFILE
else
    echo -e "\n❌ No I2C devices detected. Please check your connections." | tee -a $LOGFILE
    echo "Here is the i2cdetect output:"
    echo "$i2cdetect_output"
    exit 1
fi

########################################
# DISPLAY SELECTION MENU
echo
echo "Select your OLED display type:"
echo "1. SH1106"
echo "2. SSD1306"
read -p "Enter your choice (1 or 2): " display_choice

case $display_choice in
    1)
        DISPLAY_SCRIPT="display-sh1106.py"
        ;;
    2)
        DISPLAY_SCRIPT="display-ssd1306.py"
        ;;
    *)
        echo "Invalid display selection. Exiting."
        exit 1
        ;;
esac

########################################
pause_step "Add selected display script to autorun"

read -p "Enter your Raspberry Pi username (e.g., pi): " pi_user
OLED_SCRIPT_PATH="/home/$pi_user/RaspberryPi-OLED/$DISPLAY_SCRIPT"
PYTHON_VENV="/home/$pi_user/stats_env/bin/python3"

chmod +x "$OLED_SCRIPT_PATH"

(crontab -l 2>/dev/null | grep -v "$DISPLAY_SCRIPT"; echo "@reboot $PYTHON_VENV $OLED_SCRIPT_PATH &") | crontab -

########################################
pause_step "Run the selected display script now for testing"

run_cmd "python3 $DISPLAY_SCRIPT"

echo -e "${GREEN}\n🎉 DONE! The display will now auto-run on Raspberry Pi startup.${NC}" | tee -a $LOGFILE
