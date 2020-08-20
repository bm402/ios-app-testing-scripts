#!/bin/bash

#set -e

# Functions
function printTitle {
    echo >> "$outputfile"
    echo "[*] $1" >> "$outputfile"
    echo >> "$outputfile"
    echo
    echo "[*] $1"
    echo
}

function printContentWithHeading {
    echo "$1:" >> "$outputfile"
    echo "$2" >> "$outputfile"
    echo >> "$outputfile"
    echo "$1:"
    echo "$2"
    echo
}

function printContent {
    echo "$1" >> "$outputfile"
    echo >> "$outputfile"
    echo "$1"
    echo
}

function plistXmlToJson {
    plistjsonfile="$RANDOM.json"
    plutil -convert json -o "$plistjsonfile" "$1"
    plistjson=`cat "$plistjsonfile" | jq .`
    rm "$plistjsonfile"
}

function classDump {
    printTitle "Interesting $2 classes"
    dumpfile="class-dump-$2-$1-$timestamp.txt"
    dsdump --"$2" --verbose=0 --arch arm64 --defined "$HOME/Documents/ios-apps/$1/AppFiles/$1" > "$dumpfile"
    dsdump --"$2" --verbose=5 --arch arm64 --defined "$HOME/Documents/ios-apps/$1/AppFiles/$1" > "$curdir/$dumpfile"
    for word in "${words[@]}"; do
        classes=`grep -iF "$word" "$dumpfile"`
        if [ ! -z "$classes" ]; then
            printContentWithHeading "$word" "$classes"
        fi
    done
    rm "$dumpfile"
}

# Usage
if [ -z "$1" ]; then
    echo "[*] Usage: $0 [app name]"
    exit 1
fi

# Navigate to directory
curdir=`pwd`
cd "$HOME/Documents/ios-apps/$1/AppFiles"

# Create output file
timestamp=`date +"%Y%m%d%H%M%S"`
outputfile="$curdir/static-analysis-$1-$timestamp.txt"
touch "$outputfile"

# Find Info.plist, convert to JSON and print
printTitle "Info.plist"
plistjson=
plistXmlToJson "Info.plist"
printContent "$plistjson"
infoplistjson="$plistjson"

# Find plist files, convert to JSON and print
printTitle "Other .plist files"
plists=`find . -name "*.plist" | grep -v -E ".storyboardc|/Frameworks/|./Info.plist"`
for plist in $plists; do
    plistjson=
    plistXmlToJson "$plist"
    plistname=`echo "$plist" | cut -c 3-`
    printContentWithHeading "$plistname" "$plistjson"
done

# Class dumps
words=(Debug Test Dummy Old Legacy Secret Key Encrypt Encode Decrypt Decode Random)
classDump "$1" "objc"
classDump "$1" "swift"

# Strings
