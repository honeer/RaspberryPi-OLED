#!/bin/bash

set -e

LOGFILE="install_log.txt"
touch $LOGFILE

echo "Starting Raspberry Pi OLED setup..." | tee -a $LOGFILE

function pause_step() {
    read -p "Proceed to: $1 (y/n)? " yn
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

pause_step "Install Adafruit Blinka and setup I2C"
run_cmd "pip install --upgrade adafruit-python-shell"
run_cmd "wget https://raw.githubusercontent.com/adafruit/Raspberry-Pi-Installer-Scripts/master/raspi-blinka.py"
run_cmd "sudo -E env PATH=$PATH python3 raspi-blinka.py"

pause_step "Run i2cdetect to verify display connection"
run_cmd "sudo i2cdetect -y 1"

pause_step "Install OLED display drivers and dependencies"
run_cmd "pip install --upgrade adafruit_blinka"
run_cmd "pip install luma.oled"
run_cmd "sudo apt-get install -y python3-pil libjpeg-dev libfreetype6-dev python3-dev"

pause_step "Clone OLED display script repository"
deactivate
run_cmd "sudo apt-get install -y git"
run_cmd "git clone https://github.com/honeer/RaspberryPi-OLED"

pause_step "Reactivate virtual environment and enter script folder"
source stats_env/bin/activate
cd RaspberryPi-OLED

# DISPLAY SELECTION MENU
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

pause_step "Run the appropriate display test script"
run_cmd "python3 $DISPLAY_SCRIPT"

pause_step "Setup autostart (edit username as needed)"
read -p "Enter your Raspberry Pi username (e.g., pi): " pi_user
OLED_SCRIPT_PATH="/home/$pi_user/RaspberryPi-OLED/$DISPLAY_SCRIPT"
PYTHON_VENV="/home/$pi_user/stats_env/bin/python3"

# Make sure the script is executable (for good measure)
chmod +x "$OLED_SCRIPT_PATH"

# Add to crontab
(crontab -l 2>/dev/null; echo "@reboot $PYTHON_VENV $OLED_SCRIPT_PATH &") | crontab -

echo "✅ Setup complete! Your display will run on boot." | tee -a $LOGFILE
