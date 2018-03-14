#!/bin/sh -e
VERSION="testing_0.1.5"
HOSTNAME="$1"
VOL_DIR="/etc/wispro"
if [ -z "$HOSTNAME" ]; then
	echo "usage: $0 hostname"
	exit 1
fi

cleanup() {
	rm -rf "$tmp"
}

makefile() {
	OWNER="$1"
	PERMS="$2"
	FILENAME="$3"
	cat > "$FILENAME"
	chown "$OWNER" "$FILENAME"
	chmod "$PERMS" "$FILENAME"
}

rc_add() {
	mkdir -p "$tmp"/etc/runlevels/"$2"
	ln -sf /etc/init.d/"$1" "$tmp"/etc/runlevels/"$2"/"$1"
}


tmp="$(mktemp -d)"
trap cleanup EXIT

mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

mkdir -p "$tmp"/${VOL_DIR}
mrdialog_gemfile="mrdialog-1.0.3.gem"

makefile root:root 0755 "$tmp"/${VOL_DIR}/install <<EOF
gem install --local /etc/wispro/${mrdialog_gemfile}
${VOL_DIR}/wispro_installer/alpine-install.rb
EOF

curl -sL https://github.com/muquit/mrdialog/blob/master/pkg/mrdialog-1.0.3.gem?raw=true > ${tmp}/${VOL_DIR}/${mrdialog_gemfile}
git clone --branch ${VERSION} https://github.com/sequre/wispro_installer ${tmp}/${VOL_DIR}/wispro_installer
mkdir -p "$tmp"/etc/apk

makefile root:root 0644 "$tmp"/etc/apk/world <<EOF
alpine-base
network-extras
iptables
iproute2
mii-tool
ethtool
fping
curl
conntrack-tools
ipset
dnsmasq
bash
bash-completion
docker
logrotate
lsof
vim
pax-utils
paxmark
pciutils
screen
strace
sudo
tmux
xtables-addons
acct
arpon
arpwatch
awall
bridge-utils
bwm-ng
ca-certificates
cutter
cyrus-sasl
dhcp
dhcpcd
dhcrelay
dnsmasq
email
fprobe
haserl
htop
igmpproxy
ip6tables
iproute2-qos
iputils
ppp
tcpdump
mkinitfs
mtools
nfs-utils
parted
rsync
sfdisk
syslinux
util-linux
tzdata
ruby
dialog
EOF

rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit
rc_add modloop sysinit

rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add hostname boot
rc_add bootmisc boot
rc_add syslog boot

rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

tar -c -C "$tmp" etc | gzip -9n > $HOSTNAME.apkovl.tar.gz
