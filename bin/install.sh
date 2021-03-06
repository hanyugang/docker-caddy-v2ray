#!/usr/bin/env bash

cat << EOF
1. 默认配置 DNS server 为 8.8.8.8 和 8.8.4.4
EOF
# update dns server
dns_config=/etc/resolv.conf
sed -i 's/^nameserver.*$//g' $dns_config
echo "
nameserver 8.8.8.8
nameserver 8.8.4.4
" >> $dns_config

## delete blank rows
sed -i '/^$/d' /etc/resolv.conf

###### 需要安装的软件
install_apps=(curl git vim net-tools mlocate wget ufw gettext coreutils)
# 判断系统类型
if [[ $(command -v yum) ]]; then
    # RHEL(CentOS)
    echo "install apps ${install_apps[*]} bind-utils "
    yum install -y ${install_apps[*]} bind-utils
else
    # Debian(Ubuntu)
    echo "install apps ${install_apps[*]} dnsutils "
    apt install -y ${install_apps[*]} dnsutils
fi

echo "git clone 仓库......"
git clone https://github.com/yuanmomo/docker-caddy-v2ray.git \
    && chmod +x `pwd`/docker-caddy-v2ray/bin/v2ray.sh \
    && ln -s -f `pwd`/docker-caddy-v2ray/bin/v2ray.sh  /usr/local/bin/v2ray \

###### ufw 配置
source `pwd`/docker-caddy-v2ray/bin/source/ufw.sh
#开启防火墙
enable_ufw

###### 更新 ssh 配置
key_word="#INITIALIZED by MoMo"
if [[ ! $(grep "${key_word}" /etc/ssh/sshd_config) ]] ; then
    # update ssh port and set only rsa login only
    bash `pwd`/docker-caddy-v2ray/bin/util/ssh-config.sh
    echo "${key_word}">> /etc/ssh/sshd_config
fi

###### 安装 docker && docker-compose
if [[ ! $(command -v docker) || ! $(command -v docker-compose) ]]; then
    bash <(curl -s -L https://git.io/JeZ5P)
fi


# 执行命令
v2ray config

