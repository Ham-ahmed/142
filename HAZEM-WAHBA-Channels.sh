#!/bin/sh

# =====================================================
# Configuration
# =====================================================
channel="HAZEM-WAHBA_motor"
url="https://raw.githubusercontent.com/Ham-ahmed/142/refs/heads/main/channels_backup_OpenBlackhole_20260214_HAZEMWAHBA-CIEFP.tar.gz"

# =====================================================
# Remove unnecessary files and folders (cleanup)
# =====================================================
[ -d "/CONTROL" ] && rm -r /CONTROL >/dev/null 2>&1
rm -f /control /postinst /preinst /prerm /postrm >/dev/null 2>&1
rm -f /tmp/*.ipk /tmp/*.tar.gz >/dev/null 2>&1

# =====================================================
# Check if wget is installed
# =====================================================
if ! command -v wget >/dev/null 2>&1; then
    echo "> wget not found! Please install wget."
    exit 1
fi

# =====================================================
# Download channel file
# =====================================================
echo "> Downloading $channel channels... Please wait"
sleep 2

# Temporary download file
tmp_file="/tmp/$channel.tar.gz"

# Download file with progress bar
wget --show-progress -q "$url" -O "$tmp_file"

# Check if download was successful
if [ $? -ne 0 ] || [ ! -f "$tmp_file" ]; then
    echo "> Download failed! Check internet connection or URL."
    exit 1
fi

# Check if downloaded file is valid (not empty and is gzip)
if [ ! -s "$tmp_file" ] || ! file "$tmp_file" | grep -q "gzip compressed data"; then
    echo "> Downloaded file is invalid or corrupted!"
    rm -f "$tmp_file"
    exit 1
fi

# =====================================================
# Remove old channel files
# =====================================================
echo "> Removing old channels..."
rm -rf /etc/enigma2/lamedb /etc/enigma2/*.tv /etc/enigma2/*.radio /etc/enigma2/*list /etc/tuxbox/*.xml >/dev/null 2>&1

# =====================================================
# Extract new files
# =====================================================
echo "> Extracting new channel files..."
cd /tmp || exit 1

# Extract with error handling
if ! tar -xzf "$channel.tar.gz" -C /; then
    echo "> Extraction failed! File may be corrupted."
    rm -f "$channel.tar.gz"
    exit 1
fi

# Remove compressed file after extraction
rm -f "$channel.tar.gz"

echo "> $channel channels installed successfully."

# =====================================================
# Restart ENIGMA2 interface
# =====================================================
# Try to reload service list via web (optional, may not work on all devices)
wget -qO- "http://127.0.0.1/web/servicelistreload?mode=0" >/dev/null 2>&1
sleep 1

echo "> Restarting Enigma2..."

# Determine restart method based on system
if command -v systemctl >/dev/null 2>&1; then
    # Systems using systemd (like OpenATV 6.4+, OpenPLi 8+)
    if systemctl is-active enigma2 >/dev/null 2>&1; then
        systemctl restart enigma2
    else
        # Try alternative service names
        systemctl restart enigma2-openpli 2>/dev/null || \
        systemctl restart enigma2-opendreambox 2>/dev/null || \
        killall -9 enigma2 2>/dev/null
    fi
elif command -v init >/dev/null 2>&1; then
    # Older systems without systemd
    killall -9 enigma2 2>/dev/null || init 3
else
    # Fallback method
    killall -9 enigma2 2>/dev/null
    sleep 2
    enigma2 >/dev/null 2>&1 &
fi

echo "> Done."
exit 0