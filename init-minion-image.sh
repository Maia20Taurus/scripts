set -euo pipefail

# todo, some kind of ./init-minion-image.sh <DIRECTORY>, which sets var where needed in the script

debootstrap --arch arm64 --include tinysshd stable /TODO_CHANGE_THIS https://deb.debian.org/debian 

# https://sabotage-linux.neocities.org/blog/12/


# 3) trim the fat part1, installation leftovers:
# rm DIRECTORY/var/cache/apt/archives/*.deb
# rm DIRECTORY/var/cache/apt/*cache.bin
# rm DIRECTORY/var/cache/debconf/*.dat-old
# rm -rf DIRECTORY/var/lib/apt/lists/*

# 4) trim the fat part2, unneeded documentation and translation:
# rm -rf DIRECTORY/usr/share/doc/*
# rm -rf DIRECTORY/usr/share/locale/*
# rm -rf DIRECTORY/usr/share/man/*

# 6) edit DIRECTORY/etc/dpkg/dpkg.cfg and add the following 3 lines:
# path-exclude=/usr/share/doc/*
# path-exclude=/usr/share/locale/*
# path-exclude=/usr/share/man/*