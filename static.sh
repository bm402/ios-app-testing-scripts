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
words=(Debug Test Dummy Old Legacy Secret Key Encrypt Encode Decrypt Decode)

printTitle "Interesting objc classes"
dumpfileobjc="class-dump-objc-$1-$timestamp.txt"
dsdump --objc --verbose=0 --arch arm64 --defined "$HOME/Documents/ios-apps/$1/AppFiles/$1" > "$dumpfileobjc"
dsdump --objc --verbose=5 --arch arm64 --defined "$HOME/Documents/ios-apps/$1/AppFiles/$1" > "$curdir/$dumpfileobjc"
for word in "${words[@]}"; do
    classes=`grep -iF "$word" "$dumpfileobjc"`
    if [ ! -z "$classes" ]; then
        printContentWithHeading "$word" "$classes"
    fi
done
rm "$dumpfileobjc"

printTitle "Interesting swift classes"
dumpfileswift="class-dump-swift-$1-$timestamp.txt"
dsdump --swift --verbose=0 --arch arm64 --defined "$HOME/Documents/ios-apps/$1/AppFiles/$1" > "$dumpfileswift"
dsdump --swift --verbose=5 --arch arm64 --defined "$HOME/Documents/ios-apps/$1/AppFiles/$1" > "$curdir/$dumpfileswift"
for word in "${words[@]}"; do
    classes=`grep -iF "$word" "$dumpfileswift"`
    if [ ! -z "$classes" ]; then
        printContentWithHeading "$word" "$classes"
    fi
done
rm "$dumpfileswift"
