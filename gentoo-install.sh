#!/usr/bin/env bash
# This is a recipe; not a script. You should try to run it chunk by chunck.
# The shebang is only for syntax highlighting

# Chroot
## Please, run this right after running script 00
mount -o defaults,relatime,compress=lzo,autodefrag,subvol=root /dev/vda4 /mnt/gentoo

## create dirs for mounts
cd /mnt/gentoo
mkdir srv home root var boot

## mount
mount -o defaults,relatime,compress=lzo,autodefrag,subvol=home /dev/vda4 /mnt/gentoo/home
mount -o defaults,relatime,compress=lzo,autodefrag,subvol=srv /dev/vda4 /mnt/gentoo/srv
mount -o defaults,relatime,compress=lzo,autodefrag,subvol=var /dev/vda4 /mnt/gentoo/var
mount -o defaults,relatime /dev/vda2 /mnt/gentoo/boot

### efi partition
mount -o defaults,noatime /dev/vda1 /mnt/gentoo/boot/efi

## get gentoo stage3
wget https://distfiles.gentoo.org/releases/amd64/autobuilds/20240128T165521Z/stage3-amd64-desktop-openrc-20240128T165521Z.tar.xz

## uncompress
tar -xapf stage3-amd64-nomultilib-systemd-20211121T170545Z.tar.xz
rm -f $_

## mount proc, sys and dev
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

## activate swap
swapon /dev/vda3

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
/dev/vda4   /               btrfs   rw,relatime,compress=zstd:1,autodefrag,subvol=root   0 0
/dev/vda4   /home           btrfs   rw,relatime,compress=zstd:1,autodefrag,subvol=home   0 0
/dev/vda4   /srv            btrfs   rw,relatime,compress=zstd:1,autodefrag,subvol=srv    0 0
/dev/vda4   /var            btrfs   rw,relatime,compress=zstd:1,autodefrag,subvol=var    0 0
/dev/vda3   none            swap    sw                                                  0 0
/dev/vda2   /boot           btrfs   rw,relatime                                          1 2
/dev/vda1   /boot/efi       vfat    umask=0077,shortname=winnt                          0 2
EOF

## local time in MX
ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

## add cpu flags
emerge app-portage/cpuid2cpuflags
cpu_flags=$( cpuid2cpuflags | cut -d ' ' -f '2-' )

## append to my make.conf
use_remove='-accessibility -altivec -apache2 -aqua -big-endian -bindist -boundschecking -bsf -canna -clamav -connman -coreaudio -custom-cflags -debug -dedicated -emacs -handbook -ibm -infiniband -iwmmxt -kde -kontact -libav -libedit -libressl -libsamplerate -mono -mule -neon -oci8 -oci8-instant-client -oracle -oss -pch -pcmcia -plasma -qmail-spp -qt4 -qt5 -static -syslog -sysvipc -tcpd -xemacs -yahoo -zsh-completion'
use_add='symlink unicode vim-syntax'
make_opts="-j$(( $( nproc ) + 1 ))"

cat << EOF > /etc/portage/make.conf
CFLAGS="-mtune=native -O2 -pipe"
CXXFLAGS=\${CFLAGS}
CHOST="x86_64-pc-linux-gnu"
CPU_FLAGS_X86="${cpu_flags}"
GRUB_PLATFORMS="efi-64"
# enable this if you like living on the edge
#ACCEPT_KEYWORDS="~amd64"
MAKEOPTS="${make_opts}"
ADD="${use_add}"
REMOVE="${use_remove}"
USE="\$REMOVE \$ADD"
# Portage Opts
FEATURES="parallel-fetch parallel-install ebuild-locks"
EMERGE_DEFAULT_OPTS="--with-bdeps=y"
AUTOCLEAN="yes"
EOF

## set profiles
eselect profile set default/linux/amd64/17.1/no-multilib/systemd/merged-usr

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

# Configure real root and stuff
# Do not forget to append systemd to the kernel command line: GRUB_CMDLINE_LINUX="real_init=/lib/systemd/systemd quiet"
vim /etc/default/grub

## install grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi

# update grub
grub-mkconfig -o /boot/grub/grub.cfg

# systemd
## Setup machine ID to activate journaling
systemd-machine-id-setup

## DHCP
cat << 'EOF' > /etc/systemd/network/20-default.network
[Match]
Name = enp*
[Network]
DHCP = yes
EOF

systemctl enable systemd-networkd.socket

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
