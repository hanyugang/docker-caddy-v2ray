#!/usr/bin/env bash
# update ssh port and set only rsa login only

current_dir=$(cd "$(dirname "$0")";pwd)

# 脚本说明
cat << EOF
1. 配置 SSH 服务
    1.1 修改 sshd port
    1.2 禁用密码登陆，仅允许免密登陆
    1.3 禁用 DNS 反向解析
    1.4 GSSAPIAuthentication
2. ufw 开启 ssh 端口
EOF

# 读取用户输入脚本
source ${current_dir}/../source/read-input.sh

# change ssh config
readInput "是否需要修改 SSH 配置, (y/n)? (默认: n) " "^([y]|[n])$" "n"
changeSsh=${read_value}

if [[ ${changeSsh} == y ]]; then
    readInput "请指定 SSH 新的端口号 (可用范围为0-65535), 默认 27392:  ? " "^([0-9]{1,4}|[1-5][0-9]{4}|6[0-5]{2}[0-3][0-5])$" "27392"
    Port=${read_value}

    echo "请注意修改防火墙，打开 SSH 端口 : ${Port}"

    # update port
    sed -i 's/^Port/#Port/g' /etc/ssh/sshd_config
    # turn off password authentication
    sed -i 's/^PasswordAuthentication/#PasswordAuthentication/g' /etc/ssh/sshd_config
    # turn off dns
    sed -i 's/^UseDNS/#UseDNS/g' /etc/ssh/sshd_config
    # turn off GSSAPIAuthentication
    sed -i 's/^GSSAPIAuthentication/#GSSAPIAuthentication/g' /etc/ssh/sshd_config

    echo "Port ${Port}">> /etc/ssh/sshd_config
    echo "PasswordAuthentication no">> /etc/ssh/sshd_config
    echo "UseDNS no">> /etc/ssh/sshd_config
    echo "GSSAPIAuthentication no">> /etc/ssh/sshd_config

    old_ssh_port=`netstat -anp | grep -i -w tcp | grep LISTEN | grep sshd| awk '{print $4}' | cut -f 2 -d ':'`

    service sshd restart

    # iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${Port} -j ACCEPT
    # ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${Port} -j ACCEPT
    
    echo "删除防火墙旧的 SSH 规则: ${old_ssh_port}"
    ufw --force delete allow ${old_ssh_port}/tcp

    echo "打开防火墙旧的 SSH 规则 : ${Port}"
    ufw allow ${Port}/tcp
    ufw status verbose
fi