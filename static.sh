#!/bin/bash

# Utility functions
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

function printContentInList {
    echo "$1" >> "$outputfile"
    echo "$1"
}

function plistXmlToJson {
    plistjsonfile="$RANDOM.json"
    plutil -convert json -o "$plistjsonfile" "$1"
    plistjson=`cat "$plistjsonfile" | jq .`
    rm "$plistjsonfile"
}

function findIndicators {
    indicators=`rabin2 -z -zz "$1" | egrep -i "$2"`
    if [ ! -z "$indicators" ]; then
        printContentWithHeading "$2" "$indicators"
    fi
}

# Usage
if [ -z "$1" ]; then
    echo "[*] Usage: $0 [app name]"
    exit 1
fi

# Global variables
curdir=`pwd`
appfilesdir="$HOME/Documents/ios-apps/$1/AppFiles"
appbinary="$appfilesdir/$1"
timestamp=`date +"%Y%m%d%H%M%S"`

# Navigate to directory
cd "$appfilesdir"

# Create output file
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

# Find JSON files and print
printTitle ".json files"
jsons=`find . -name "*.json"`
for json in $jsons; do
    jsoncontent=`cat $json | jq .`
    jsonname=`echo "$json" | cut -c 3-`
    printContentWithHeading "$jsonname" "$jsoncontent"
done

# Find config files and print
printTitle ".conf files"
confs=`find . -name "*.conf"`
for conf in $confs; do
    confcontent=`cat $conf`
    confname=`echo "$conf" | cut -c 3-`
    printContentWithHeading "$confname" "$confcontent"
done

# Find Core Data files
printTitle "Core Data files"
moms=`find . -name "*.mom*"`
for mom in $moms; do
    momname=`echo "$mom" | cut -c 3-`
    printContent "$momname"
done

# List other interesting files
printTitle "Other potentially interesting files"
files=`find . | sed "s/ /_/g" | grep -v -E ".plist|.json|.conf|.mom|.storyboardc|/Frameworks/|.xib|.nib|.png|.jpg|.svg"`
for file in $files; do
    filename=`echo "$file" | cut -c 3-`
    printContentInList "$filename"
done
echo

# Class dumps
words=(Debug Test Dummy Develop Fake Legacy Internal Secret Private Key Token Encrypt Encod Decrypt Decod Random Password Authenticat User Credential)
function classDump {
    printTitle "Interesting $2 classes"
    dumpfile="class-dump-$2-$1-$timestamp.txt"
    dsdump --"$2" --verbose=0 --arch arm64 --defined "$appbinary" > "$dumpfile"
    dsdump --"$2" --verbose=5 --arch arm64 --defined "$appbinary" > "$curdir/$dumpfile"
    for word in "${words[@]}"; do
        classes=`grep -iF "$word" "$dumpfile"`
        if [ ! -z "$classes" ]; then
            printContentWithHeading "$word" "$classes"
        fi
    done
    rm "$dumpfile"
}
classDump "$1" "objc"
classDump "$1" "swift"

# Strings
printTitle "Interesting strings in binary"
stringsfile="strings-$1-$timestamp.txt"
strings "$appbinary" > "$stringsfile"
for word in "${words[@]}"; do
    strings=`grep -iF "$word" "$stringsfile"`
    if [ ! -z "$strings" ]; then
        printContentWithHeading "$word" "$strings"
    fi
done

printTitle "URLs in binary"
urls=`grep -iF "://" "$stringsfile"`
if [ ! -z "$urls" ]; then
    printContent "$urls"
fi

printTitle "Possible IDs in binary"
an64s=`grep -E '^[[:alnum:]]{64,64}$' "$stringsfile"`
if [ ! -z "$an64s" ]; then
    printContentWithHeading "Alphanumeric strings with 64 characters" "$an64s"
fi
uuids=`grep -E '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$' "$stringsfile"`
if [ ! -z "$uuids" ]; then
    printContentWithHeading "UUIDs" "$uuids"
fi
rm "$stringsfile"

# WebView indicators
printTitle "UIWebViews"
findIndicators "$1" "UIWebView"
findIndicators "$1" "baseURL"
findIndicators "$1" "allowingReadAccessToURL"
findIndicators "$1" "JSContext"
findIndicators "$1" "JSExport"

printTitle "SFSafariViewController"
findIndicators "$1" "SFSafariViewController"

printTitle "WKWebViews"
findIndicators "$1" "WKWebView"
findIndicators "$1" "javascriptEnabled"
findIndicators "$1" "hasOnlySecureContent"
findIndicators "$1" "allowFileAccessFromFileURLs"
findIndicators "$1" "allowUniversalAccessFromFileURLs"
findIndicators "$1" "WKScriptMessageHandler"

# Object encoding indicators
printTitle "Object encoding"
findIndicators "$1" "NSCoding"
findIndicators "$1" "NSSecureCoding"

# Info.plist summary
printTitle "Info.plist summary"
function infoPlistSection {
    section=`echo "$infoplistjson" | jq ".$1?"`
    printContentWithHeading "$1" "$section"
}
infoPlistSection "CFBundleURLTypes"
infoPlistSection "LSApplicationQueriesSchemes"
infoPlistSection "NSAppTransportSecurity"
infoPlistSection "UTImportedTypeDeclarations"
infoPlistSection "UTExportedTypeDeclarations"
infoPlistSection "CFBundleDocumentTypes"

# File message
printTitle "Static analysis finished, output file saved to $outputfile"
