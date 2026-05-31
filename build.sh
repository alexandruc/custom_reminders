#!/bin/bash
# Build script for Custom Reminders Garmin app
# Requires Connect IQ SDK installed and developer key available

SDK_DIR="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b"
MONKEYC="$SDK_DIR/bin/monkeyc"
KEY="$(dirname "$0")/../developer_key"

echo "Building Custom Reminders..."

"$MONKEYC" \
  -w \
  --package-app \
  -y "$KEY" \
  -f monkey.jungle \
  -o bin/CustomReminders.iq

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Output: bin/CustomReminders.iq"
    ls -lh bin/CustomReminders.iq
else
    echo "Build failed!"
    exit 1
fi
