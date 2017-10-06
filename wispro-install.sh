#!/bin/sh
# First time only building immage
# echo PermitRootLogin yes >> /etc/ssh/sshd_config
# service sshd restart

alpine_version="v3.6"
alpine_mirror="dl-3.alpinelinux.org"
wispro_version="latest"
wispro_dir="/usr/src/app"
wispro_binary="/usr/local/bin/wispro"
wispro_binary_url=https://raw.githubusercontent.com/sequre/wispro_installer/master/wispro
cat >> /etc/apk/repositories <<END
https://${alpine_mirror}/alpine/${alpine_version}/main
https://${alpine_mirror}/alpine/${alpine_version}/community
END

apk update
apk add iptables iproute2 mii-tool ethtool fping docker curl conntrack-tools ipset dnsmasq bash bash-completion

echo . /etc/profile.d/bash_completion.sh >> /root/.bashrc
sed -i 's/ash/bash/' /etc/passwd


echo "wispro-host" > /etc/hostname
hostname -F /etc/hostname

service docker start
rc-update add docker default

# Docker compose is no longer needed, using docker exec/run directly
#curl -L --fail https://github.com/docker/compose/releases/download/1.15.0/run.sh -o /usr/local/bin/docker-compose
#chmod +x /usr/local/bin/docker-compose
## first run will download the docker image
#docker-compose &2> /dev/null

# Wispro BMU app
mkdir -p ${wispro_dir}
mkdir -p ${wispro_dir}/data
mkdir -p ${wispro_dir}/tmp
mkdir -p ${wispro_dir}/log
mkdir -p ${wispro_dir}/etc
mkdir -p ${wispro_dir}/scripts

mkdir /root/.ssh && chmod 700 /root/.ssh
mkdir ${wispro_dir}/data/.ssh && chmod 700 ${wispro_dir}/data/.ssh
ssh-keygen -t rsa -N "" -f ${wispro_dir}/data/.ssh/bmu-rsa
mv ${wispro_dir}/data/.ssh/bmu-rsa.pub /root/.ssh/authorized_keys

# install de la app
docker pull wispro/bmu:${wispro_version}

# setup de wispro
curl -s $wispro_binary_url > $wispro_binary
chmod +x $wispro_binary

# Plug-off legacy interfaces configurations
service networking stop
# Clean /etc/network/interfaces
cat > /etc/network/interfaces <<END
auto lo
iface lo inet loopback
END

wispro start

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

Wispro had been successfuly installed.

You may now access the web interface from a desktop computer at

http://192.168.100.100/
User: admin@wispro.co
Pass: 12345678

EOF

