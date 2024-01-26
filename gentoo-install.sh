#!/usr/bin/env bash
# This is a recipe; not a script. You should try to run it chunk by chunck.
# The shebang is only for syntax highlighting

# Chroot
## Please, run this right after running script 00
mount -o defaults,relatime,compress=lzo,autodefrag,subvol=root /dev/nvme0n1p4 /mnt/gentoo

## create dirs for mounts
cd /mnt/gentoo
mkdir srv home root var boot

## mount
mount -o defaults,relatime,compress=lzo,autodefrag,subvol=home /dev/nvme0n1p4 /mnt/gentoo/home
mount -o defaults,relatime,compress=lzo,autodefrag,subvol=srv /dev/nvme0n1p4 /mnt/gentoo/srv
mount -o defaults,relatime,compress=lzo,autodefrag,subvol=var /dev/nvme0n1p4 /mnt/gentoo/var
mount -o defaults,relatime /dev/nvme0n1p2 /mnt/gentoo/boot

### efi partition
mount -o defaults,noatime /dev/nvme0n1p1 /mnt/gentoo/boot/efi

## get gentoo stage3
wget https://distfiles.gentoo.org/releases/amd64/autobuilds/20231217T170203Z/stage3-amd64-desktop-openrc-20231217T170203Z.tar.xz

## uncompress
tar -xapf stage3-amd64-desktop-openrc-20231217T170203Z.tar.xz
rm -f stage3-amd64-desktop-openrc-20231217T170203Z.tar.xz

## mount proc, sys and dev
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

## activate swap
swapon /dev/nvme0n1p3

## get dns
cp -u /etc/resolv.conf /mnt/gentoo/etc/

## chroot
env -i HOME=/root TERM=$TERM chroot . bash -l

## environment
env-update
source /etc/profile
export PS1="(chroot) $PS1"

# emerge
## sync repo first
emaint -A sync

## update portage
emerge --oneshot portage

# portage (git)
# ref: https://wiki.gentoo.org/wiki/Portage_with_Git

## install dependencies for emerge with git
emerge -Dju app-eselect/eselect-repository dev-vcs/git

## setup portage to use git instead of rsync
eselect repository remove gentoo
eselect repository add gentoo git https://github.com/gentoo-mirror/gentoo.git
rm -r /var/db/repos/gentoo

## sync
emaint sync -r gentoo

# Setup
## fstab
cat << 'EOF' > /etc/fstab
# <fs>      <mountpoint>    <type>  <opts>                                              <dump/pass>
shm         /dev/shm        tmpfs   nodev,nosuid,noexec                                 0 0
/dev/nvme0n1p4   /               btrfs   rw,relatime,compress=zstd:1,autodefrag,subvol=root   0 0
/dev/nvme0n1p4   /home           btrfs   rw,relatime,compress=zstd:1,autodefrag,subvol=home   0 0
/dev/nvme0n1p4   /srv            btrfs   rw,relatime,compress=zstd:1,autodefrag,subvol=srv    0 0
/dev/nvme0n1p4   /var            btrfs   rw,relatime,compress=zstd:1,autodefrag,subvol=var    0 0
/dev/nvme0n1p3   none            swap    sw                                                  0 0
/dev/nvme0n1p2   /boot           btrfs   rw,relatime                                          1 2
/dev/nvme0n1p1   /boot/efi       vfat    umask=0077                         0 2
EOF

## local time in MX
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime

## add cpu flags
emerge app-portage/cpuid2cpuflags
## append to my make.conf
use_remove="-accessibility -altivec -apache2 -aqua -big-endian -bindist -boundschecking -bsf -canna -clamav -connman -coreaudio -custom-cflags -debug -dedicated -emacs -handbook -ibm -infiniband -iwmmxt -kontact -libav -libedit -libressl -libsamplerate -mono -mule -neon -oci8 -oci8-instant-client -oracle -oss -pch -pcmcia -static -syslog -sysvipc -tcpd -xemacs -yahoo"
use_add="symlink unicode"
CFLAGS="-march=znver3 -mtune=znver3 -O3 -pipe"
CXXFLAGS=\${CFLAGS}
CHOST="x86_64-pc-linux-gnu"
CPU_FLAGS_X86=""
GRUB_PLATFORMS="efi-64"
ACCEPT_KEYWORDS="~amd64"
MAKEOPTS="--jobs 13 --load-average 9"
ADD="${use_add}"
REMOVE="${use_remove}"
USE="\$REMOVE \$ADD"
# Portage Opts
FEATURES="parallel-fetch parallel-install ebuild-locks"
EMERGE_DEFAULT_OPTS="--getbinpkgs --binpkg-respect-use=y --with-bdeps=y"
AUTOCLEAN="yes"


## set profiles
eselect profile set default/linux/amd64/23.0/desktop/kde

## update everything and cleanup
emerge -DNju @world
emerge -c

## configure os-prober to mount grub
cat << 'EOF' > /etc/portage/package.use/os-prober
>=sys-boot/grub-2.06-r7 mount
EOF

## install useful apps
emerge -DNju vim bash-completion btrfs-progs
emerge -DNju app-portage/eix app-portage/gentoolkit sys-process/htop sys-process/lsof sys-boot/os-prober

## install vanilla sources and genkernel-next
mkdir -p /etc/portage/package.license

cat << 'EOF' > /etc/portage/package.license/linux-firmware
sys-kernel/linux-firmware linux-fw-redistributable no-source-code
EOF

emerge -DNju genkernel sys-kernel/gentoo-sources sys-kernel/linux-firmware

## Remember to enable:
## 	 * all virtio devices; at least: virtio_pci and virtio_blk
##	 * btrfs support
genkernel --menuconfig --btrfs --virtio all

## install grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi

# update grub
grub-mkconfig -o /boot/grub/grub.cfg

# set root password
passwd

# reboot (and pray, think wishfully, cross your fingers or whatever you do to influence reality... not!)
reboot

# after reboot
## set hostname
# hostnamectl set-hostname my.example.tld

## set locale (after reboot)
# localectl set-locale LANG=<LOCALE>

## set time and date
# timedatectl --help
