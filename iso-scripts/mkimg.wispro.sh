profile_wispro() {
	profile_standard
	title="Extended"
	desc="Wispro profile"
	kernel_addons="xtables-addons"
	apks="$apks
                iptables iproute2 mii-tool ethtool fping curl
                conntrack-tools
                ipset dnsmasq bash bash-completion docker
		logrotate lsof vim
		pax-utils paxmark pciutils screen strace sudo tmux
		xtables-addons

		acct arpon arpwatch awall bridge-utils bwm-ng
		ca-certificates cutter cyrus-sasl dhcp
		dhcpcd dhcrelay dnsmasq email fprobe haserl htop
		igmpproxy ip6tables iproute2-qos
		iputils
		ppp
		tcpdump

		mkinitfs mtools nfs-utils
		parted rsync sfdisk syslinux util-linux
		ruby dialog expect
		"

	local _k _a
	for _k in $kernel_flavors; do
		apks="$apks linux-$_k"
		for _a in $kernel_addons; do
			apks="$apks $_a-$_k"
		done
	done
	apks="$apks linux-firmware"
        apkovl="genapkovl-wispro.sh"
	hostname="wispro-host"
}
