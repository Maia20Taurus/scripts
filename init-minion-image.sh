#!/usr/bin/env bash

set -euo pipefail

# 1) check permissions, ensure directory is valid
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory to output image to>" >&2
    exit 1
fi

DIRECTORY="${1%/}" # Trims any trailing slash for safety

if [ -z "$DIRECTORY" ] || [ "$DIRECTORY" = "/" ]; then
    echo "invalid or dangerous out directory" >&2
    exit 1
fi

# 2) actually run debootstrap, including any packages we want 
debootstrap --arch arm64 --include tinysshd stable "$DIRECTORY" https://deb.debian.org/debian 

# https://sabotage-linux.neocities.org/blog/12/

# 3) trim the fat part1, installation leftovers:
rm -f $DIRECTORY/var/cache/apt/archives/*.deb
rm -f $DIRECTORY/var/cache/apt/*cache.bin
rm -f $DIRECTORY/var/cache/debconf/*.dat-old
rm -rf $DIRECTORY/var/lib/apt/lists/*

# 4) trim the fat part2, unneeded documentation and translation:
rm -rf $DIRECTORY/usr/share/doc/*
rm -rf $DIRECTORY/usr/share/locale/*
rm -rf $DIRECTORY/usr/share/man/*

# 6) edit DIRECTORY/etc/dpkg/dpkg.cfg and add the following 3 lines:
cat << 'EOF' >> "$DIRECTORY/etc/dpkg/dpkg.cfg"
path-exclude=/usr/share/doc/*
path-exclude=/usr/share/locale/*
path-exclude=/usr/share/man/*
EOF
