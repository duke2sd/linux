#!/bin/bash
# To-Do List Post Install
# passwd
# passwd darren
# EDITOR=nano visudo

pacman -Syu archlinux-keyring pacman-contrib --noconfirm
mkfs.vfat -F32 /dev/nvme0n1p1
mkfs.xfs /dev/nvme0n1p2 -f
mkswap /dev/nvme0n1p3
swapon /dev/nvme0n1p3
mount /dev/nvme0n1p2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/nvme0n1p1 /mnt/boot/efi
pacstrap /mnt base base-devel linux linux-headers linux-firmware intel-ucode iucode-tool archlinux-keyring sudo nano go python3-pip python3-venv xorg-server sddm xfce4 --noconfirm
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen && echo "en_US ISO-8859-1" >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt pacman -Syyu --needed nomacs git curl wget zsh fwupd packagekit-qt5 ntfs-3g dosfstools xfsprogs xfsdump grub efibootmgr networkmanager mtools pacman-contrib variety plank ccache haveged ufw bluez hplip cups go os-prober libreoffice-fresh thunderbird openssh dhcpcd acpi cpio ffmpeg ffmpegthumbnailers xf86-video-intel xarchiver galculator xdg-user-dirs-gtk --noconfirm
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
export LANG="en_US.UTF-8"
echo "archduke" > /mnt/etc/hostname
cat > /mnt/etc/hosts <<HOSTS
127.0.0.1      localhost
::1            localhost
127.0.1.1      archduke
HOSTS

arch-chroot /mnt useradd -m -G wheel darren
arch-chroot /mnt mkinitcpio -P && grub-install --target=x86_64-efi --bootloader-id=archduke && grub-mkconfig -o /boot/grub/grub.cfg
# arch-chroot /mnt systemctl enable sshd && systemctl enable NetworkManager && systemctl enable systemd-homed && systemctl enable haveged && systemctl enable ufw && systemctl enable bluetooth && systemctl enable cups && systemctl enable fstrim.timer && systemctl enable lightdm && systemctl enable dhcpcd
