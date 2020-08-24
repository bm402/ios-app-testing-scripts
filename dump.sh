#!/bin/bash

# Global variables
appsdir="$HOME/Documents/ios-apps"
fridaiosdump="$HOME/Documents/tools/frida-ios-dump/dump.py"

# Navigate to directory
cd "$appsdir"

# List available apps
echo
echo "[*] Available apps on phone:"
echo
python3 "$fridaiosdump" -l
echo

# Get name of app to dump
read -p "[*] Name of app to dump: " appname
echo

# Initiate iproxy
echo "[*] Initiating iproxy"
echo
iproxy 2222 22 &
sleep 1
echo

# Dump app
echo "[*] Dumping app"
echo
python3 "$fridaiosdump" "$appname"
echo

# Close iproxy
echo "[*] Closing iproxy"
kill %1
echo

# Extract app files
echo "[*] Extracting app files"
mkdir "$appname"
mv "$appname.ipa" "./$appname/$appname.zip"
cd "$appname"
unzip "$appname.zip" > "/dev/null"
mv "./Payload/$appname.app" "./AppFiles"
rm -rf "./Payload"
mv "$appname.zip" "$appname.ipa"
echo

# Finished
echo "[*] App dump complete, saved to $appsdir/$appname"
echo
