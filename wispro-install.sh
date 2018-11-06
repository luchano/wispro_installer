#!/bin/sh
# First time only building immage
# echo PermitRootLogin yes >> /etc/ssh/sshd_config
# service sshd restart

alpine_version="v3.6"
alpine_mirror="dl-3.alpinelinux.org"
wispro_version="0.1.8"
wispro_dir="/usr/src/app"
wispro_binary="/usr/local/bin/wispro"
wispro_binary_url=https://raw.githubusercontent.com/sequre/wispro_installer/master/wispro

echoerr() { printf "%s\n" "$*" >&2; }
finish() {
  local last_status=$?
  local last_command=${BASH_COMMAND}
  if [[ $last_status -eq 0 ]]; then
    echo "Wispro Install Successful"
    exit 0
  else
    echoerr "Wispro Install Failed on command: ${last_command}"
    exit 1
  fi
}
trap finish EXIT
set -e



cat > /etc/apk/repositories <<END
https://${alpine_mirror}/alpine/${alpine_version}/main
https://${alpine_mirror}/alpine/${alpine_version}/community
END

apk update
apk add iptables iproute2 mii-tool ethtool fping docker curl conntrack-tools ipset dnsmasq bash bash-completion tzdata dhclient ppp-pppoe rp-pppoe

echo . /etc/profile.d/bash_completion.sh >> /root/.bashrc
sed -i 's/ash/bash/' /etc/passwd

echo "wispro-host" > /etc/hostname
hostname -F /etc/hostname

if [[ -n "$DEVELOPMENT" ]]; then
  old_dir=$(pwd)
  apk add git make vim
  cd /tmp
  git clone https://github.com/gentoo/gentoo-syntax.git
  cd gentoo-syntax
  make PREFIX=~/.vim/ install
  cat > .vimrc <<EOF
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
EOF
fi

service docker start
rc-update add docker default

# damos tiempo a que levante dockerd
echo "Waiting for docker to start..."
sleep 5

# Docker compose is no longer needed, using docker exec/run directly
#curl -L --fail https://github.com/docker/compose/releases/download/1.15.0/run.sh -o /usr/local/bin/docker-compose
#chmod +x /usr/local/bin/docker-compose
## first run will download the docker image
#docker-compose &2> /dev/null

# Wispro BMU app
mkdir -p ${wispro_dir}
mkdir -p ${wispro_dir}/data
mkdir -p ${wispro_dir}/etc
mkdir -p ${wispro_dir}/log
mkdir -p ${wispro_dir}/scripts
mkdir -p ${wispro_dir}/tmp

mkdir /root/.ssh && chmod 700 /root/.ssh
mkdir ${wispro_dir}/data/.ssh && chmod 700 ${wispro_dir}/data/.ssh
ssh-keygen -t rsa -N "" -f ${wispro_dir}/data/.ssh/bmu-rsa
mv ${wispro_dir}/data/.ssh/bmu-rsa.pub /root/.ssh/authorized_keys

# install de la app
docker pull wispro/bmu:${wispro_version}
docker pull wispro/bmu_nginx:1.1

# setup de wispro
curl -s -w '%{http_code}' -L "https://github.com/sequre/wispro_installer/raw/${wispro_version}/wispro" -o ${wispro_binary}
chmod +x $wispro_binary
if [[ "$(curl -s -w '%{http_code}' -L "https://github.com/sequre/wispro_installer/raw/${wispro_version}/wispro" -o ${wispro_binary})" == "200" ]]; then
  chmod +x ${wispro_binary}
  if ! [[ "$(${wispro_binary} version)" == "${wispro_version}" ]]; then
    exit 1
  fi
else
  exit 1
fi

# Plug-off legacy interfaces configurations
service networking stop
# Clean /etc/network/interfaces
cat > /etc/network/interfaces <<END
auto lo
iface lo inet loopback
END

cat > /etc/resolv.conf <<END
nameserver 8.8.8.8
nameserver 8.8.4.4
END

VERSION=${wispro_version} wispro start

sleep 3
echo  <<EOF


    :::       ::: ::::::::::: ::::::::  :::::::::  :::::::::   ::::::::
    :+:       :+:     :+:    :+:    :+: :+:    :+: :+:    :+: :+:    :+:
    +:+       +:+     +:+    +:+        +:+    +:+ +:+    +:+ +:+    +:+
    +#+  +:+  +#+     +#+    +#++:++#++ +#++:++#+  +#++:++#:  +#+    +:+
    +#+ +#+#+ +#+     +#+           +#+ +#+        +#+    +#+ +#+    +#+
     #+#+# #+#+#      #+#    #+#    #+# #+#        #+#    #+# #+#    #+#
      ###   ###   ########### ########  ###        ###    ###  ########


Wispro ha sido instalado exitosamente.

Ya puedes acceder a la interfaz web desde una PC de escritorio accediendo a

http://192.168.100.100
Usuario: admin@wispro.co
Password: 12345678

Wispro had been successfully installed.

You may now access the web interface from a desktop computer at

http://192.168.100.100/
User: admin@wispro.co
Pass: 12345678

EOF

