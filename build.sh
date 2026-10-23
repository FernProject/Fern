#!/bin/bash
set -e

USER="fernuser"
PASSWD="fernos"
ROOT="fernos"

B="base"
BFS="basefs"

# copy base
rm -rf "$BFS"
cp -r "$B" "$BFS"
find "$BFS" -type f -name ".gitkeep" -delete

# compile src
echo "Compiling src/* ..."
make init
make src