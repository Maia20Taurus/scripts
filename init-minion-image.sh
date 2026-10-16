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

# 7) make the rootfs into a squashfs
mksquashfs $DIRECTORY node.squashfs -comp zstd -Xcompression-level 19 -b 1M -noappend

# exclude caches and other files example
# sudo mksquashfs ./rootfs-cpy/ node.squashfs -comp zstd -Xcompression-level 19 -b 1M -noappend -e boot proc sys dev run tmp mnt media lost+found


# TODO: configure ssh server, set up slurm and below tooling to pick up hostname from DHCP:
cat "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKosjebuhxoxF7dHtO69Mnk598IpKSgQgAZSmkIrSKV4 mammoth-minions@excs" > ~/.ssh/authorized_keys
# /etc/systemd/network/20-dhcp.network
# [Match]
# Name=en* eth*  # Target your network interfaces

# [Network]
# DHCP=yes

# [DHCPv4]
# UseHostname=yes


# Source - https://stackoverflow.com/a/51312156
# Posted by Ondrej K., modified by community. See post 'Timeline' for change history
# Retrieved 2026-10-16, License - CC BY-SA 4.0
#Everything between chroot and EOT will be run
chroot $DIRECTORY /bin/bash <<"EOT"
systemctl enable systemd-networkd
EOT
