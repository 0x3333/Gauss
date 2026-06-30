#!/bin/bash
set -e
cd "$(dirname "$0")/.."
xcodegen generate
xcodebuild -scheme Gauss -configuration Release -archivePath build/Gauss.xcarchive archive
echo "Archive created at build/Gauss.xcarchive"
