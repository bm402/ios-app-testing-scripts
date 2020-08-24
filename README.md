# iOS Application Testing Scripts

Library of bash scripts for testing iOS applications.

## static.sh

Usage:
`./static.sh <application name>`

Performs common static analysis techniques on the files of a dumped application:
- Prints Info.plist and other .plist, .json and .conf files
- Identifies other potentially interesting files, eg. CoreData files
- Finds class names that include interesting keywords
- Finds interesting strings in the application binary, including URLs, possible IDs, and other strings that include interesting keywords
- Identifies the use of WebViews and object encoding for possible attack surfaces
- Prints a summary of interesting information in Info.plist
