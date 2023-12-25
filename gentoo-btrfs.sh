#!/usr/bin/env bash

# WARNING!!
# This will obliterate all the data in your partition!! (not actually true, but act as if it was)
# Do NOT execute this script if you don't fully understand it!

# a few vars
amount_of_swap=$( free --si -g | grep Mem: | gawk '{ print $2 + 1}' )

# create directories
mkdir -p /mnt/gentoo

# create filesystems
mkfs -t vfat -F 32 /dev/nvme0n1p1
mkfs -t btrfs -L boot /dev/nvme0n1p2
mkfs -t btrfs -L btrfsroot /dev/nvme0n1p4
mkswap /dev/nvme0n1p3

# mount
## root
mount /dev/nvme0n1p4 /mnt/gentoo
mkdir -p /mnt/gentoo/boot

## boot
mount /dev/nvme0n1p2 /mnt/gentoo/boot
mkdir -p /mnt/gentoo/boot/efi


# create subvols
cd /mnt/gentoo
btrfs su cr @
cd @
btrfs su set-default .
btrfs subvol create root
btrfs subvol create home
btrfs subvol create srv
btrfs subvol create var

# unmount
cd ..
umount -l gentoo
