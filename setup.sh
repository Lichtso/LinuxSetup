loadkeys de-latin1
timedatectl set-ntp true
fdisk -l

cgdisk /dev/sdb
mkswap /dev/sdb3
swapon /dev/sdb3
mkfs.btrfs /dev/sdb4
mount /dev/sdb4 /mnt
btrfs subvol create /mnt/@root
umount /mnt
mount /dev/sdb4 /mnt -o subvol=@root
mkdir -p /mnt/mnt/bootloader /mnt/mnt/mac
mount /dev/sdb2 /mnt/mnt/bootloader
mount /dev/sdb5 /mnt/mnt/mac
nano /etc/packman.d/mirrorlist

pacstrap -D /mnt base linux-headers sudo fakeroot htop git patch vim make cmake meson ninja pkg-config lld lldb llvm clang grub grub-btrfs btrfs-progs hfsprogs dhcpcd wpa_supplicant openssh xf86-video-intel xf86-video-nouveau broadcom-wl sway light alacritty alsa-utils firefox
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

LANG='en_US.UTF-8'
HOSTNAME=
USERNAME=
PASSWORD=

rm /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc
sed -i "s/#$LANG/$LANG/g" /etc/locale.gen
locale-gen
echo "LANG=$LANG" > /etc/locale.conf
echo "KEYMAP=de-latin1" > /etc/vconsole.conf
echo "$HOSTNAME" > /etc/hostname
useradd -m -g users -G wheel -s /bin/bash $USERNAME
echo -e "$PASSWORD\n$PASSWORD" | passwd $USERNAME
echo -e "$PASSWORD\n$PASSWORD" | passwd
mv ./sudoers /etc/sudoers
# visudo

cat > /etc/systemd/network/20-wired.network <<EOL
[Match]
Name=eth0
[Network]
DHCP=true
[DHCP]
RouteMetric=10
EOL
cat > /etc/systemd/network/25-wireless.network <<EOL
[Match]
Name=wlan0
[Network]
DHCP=true
[DHCP]
RouteMetric=20
EOL
systemctl enable systemd-networkd

su $USERNAME
cd ~
mkdir -p ~/.config/sway/
mv ./sway.config ~/.config/sway/config
git clone https://aur.archlinux.org/hfsprogs.git
cd hfsprogs
makepkg -si
cd ..
git clone https://aur.archlinux.org/wob.git
cd wob
meson build
ninja -C build
sudo ninja -C build install
cd ..
git clone https://aur.archlinux.org/wofi.git
cd wofi
meson build
ninja -C build
sudo ninja -C build install
cd ..
exit

cat > /etc/profile.d/wayland.sh <<EOL
export MOZ_ENABLE_WAYLAND=1
export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
export CLUTTER_BACKEND=wayland
export SDL_VIDEODRIVER=wayland
EOL

mkdir -p /boot/grub /mnt/bootloader/mach_kernel /mnt/bootloader/System/Library/CoreServices
sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="vconsole.keymap=de-latin1 net.ifnames=0 biosdevname=0"/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-mkstandalone -o /mnt/bootloader/System/Library/CoreServices/boot.efi -d /usr/lib/grub/x86_64-efi -O x86_64-efi --compress=xz /boot/grub/grub.cfg
sed -i 's/BINARIES=()/BINARIES=("\/usr\/bin\/btrfs")/g' /etc/mkinitcpio.conf
mkinitcpio -P
exit
reboot
