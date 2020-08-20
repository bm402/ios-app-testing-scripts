#!/bin/bash

set -e

# Functions
function printToFileWithHeading {
    echo "[*] $1" >> "$outputfile"
    echo >> "$outputfile"
    echo "$2" >> "$outputfile"
    echo >> "$outputfile"
}

function printToStdoutWithHeading {
    echo "$1:"
    echo "$2"
    echo
}

function printWithHeadings {
    printToFileWithHeading "$1" "$2"
    printToStdoutWithHeading "$1" "$2"
}

function plistXmlToJson {
    plistjsonfile="$RANDOM.json"
    plutil -convert json -o "$plistjsonfile" "$1"
    plistjson=`cat "$plistjsonfile" | jq .`
    rm "$plistjsonfile"
}

# Usage
if [ -z "$1" ]; then
    echo "[*] Usage: $0 [app name]"
    exit 1
fi

# Navigate to directory
curdir=`pwd`
echo "[*] Finding app on the filesystem"
cd "$HOME/Documents/ios-apps/$1/AppFiles"

# Create output file
timestamp=`date +"%Y%m%d%H%M%S"`
outputfile="$curdir/static-analysis-$1-$timestamp.txt"
touch "$outputfile"

# Find Info.plist, convert to JSON and print
echo "[*] Getting Info.plist"
echo
plistjson=
plistXmlToJson "Info.plist"
printWithHeadings "Info.plist" "$plistjson"

# Find plist files, convert to JSON and print
echo "[*] Finding other .plist files"
plists=`find . -name "*.plist" | grep -v -E ".storyboardc|/Frameworks/|./Info.plist"`
echo
for plist in $plists; do
    plistjson=
    plistXmlToJson "$plist"
    plistname=`echo "$plist" | cut -c 3-`
    printWithHeadings "$plistname" "$plistjson"
done
