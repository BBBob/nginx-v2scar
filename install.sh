#!/bin/bash
#判断系统
#if [ ! -e '/etc/redhat-release' ]; then
#echo "仅支持centos7"
#exit
#fi
#if  [ -n "$(grep ' 6\.' /etc/redhat-release)" ] ;then
#echo "仅支持centos7"
#exit
#fi

function blue(){
    echo -e "\033[34m\033[01m $1 \033[0m"
}
function green(){
    echo -e "\033[32m\033[01m $1 \033[0m"
}
function red(){
    echo -e "\033[31m\033[01m $1 \033[0m"
}
function yellow(){
    echo -e "\033[33m\033[01m $1 \033[0m"
}

install_ssl(){
    green "======================"
    green " 输入解析到此VPS的域名"
    green "======================"
    read domain
    mkdir -p /etc/nginx/ssl/$domain

    green "======================"
    green " 输入ssl证书email"
    green "======================"
    read email

    ~/.acme.sh/acme.sh --register-account -m $email
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

    ~/.acme.sh/acme.sh  --issue  -d $domain  --webroot /etc/nginx/html/
    ~/.acme.sh/acme.sh  --installcert  -d  $domain   \
        --key-file   /etc/nginx/ssl/$domain/$domain.key \
        --fullchain-file /etc/nginx/ssl/$domain/fullchain.cer \
        --reloadcmd  "systemctl restart nginx"

}

install_domain(){
    green "======================"
    green " 输入解析到此VPS的域名"
    green "======================"
    read domain

cat > /etc/nginx/conf.d/$domain.conf<<-EOF
server {
    listen       80;
    server_name  $domain;
    root /etc/nginx/html;
    index index.php index.html index.htm;
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /etc/nginx/html;
    }
}
EOF

    systemctl stop nginx
    systemctl start nginx

    curl https://get.acme.sh | sh

    green "======================"
    green " 输入ssl证书email"
    green "======================"
    read email

    ~/.acme.sh/acme.sh --register-account -m $email
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
 
    mkdir -p /etc/nginx/ssl/$domain

    ~/.acme.sh/acme.sh  --issue  -d $domain  --webroot /etc/nginx/html/
    ~/.acme.sh/acme.sh  --installcert  -d  $domain   \
        --key-file   /etc/nginx/ssl/$domain/$domain.key \
        --fullchain-file /etc/nginx/ssl/$domain/fullchain.cer \
        --reloadcmd  "systemctl restart nginx"
	
cat > /etc/nginx/conf.d/$domain.conf<<-EOF
server { 
    listen       80;
    server_name  $domain;
    rewrite ^(.*)$  https://\$host\$1 permanent; 
}
server {
    listen 443 ssl http2;
    server_name $domain;
    root /etc/nginx/html;
    index index.php index.html;
    ssl_certificate /etc/nginx/ssl/$domain/fullchain.cer; 
    ssl_certificate_key /etc/nginx/ssl/$domain/$domain.key;
    #TLS 版本控制
    ssl_protocols   TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers     'TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5';
    ssl_prefer_server_ciphers   on;
    ssl_stapling on;
    ssl_stapling_verify on;
    #add_header Strict-Transport-Security "max-age=31536000";
    #access_log /var/log/nginx/access.log combined;
    location /video {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10086; 
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
    location / {
       try_files \$uri \$uri/ /index.php?\$args;
    }
}
EOF

}

#安装nginx
install_nginx(){
 
    systemctl stop firewalld
    systemctl disable firewalld
    yum install -y wget unzip nginx

    mkdir -p /etc/nginx/html
    cd /etc/nginx/html
    rm -f /etc/nginx/html/*
    wget https://github.com/BBBob/nginx-v2scar/raw/master/web.zip
    unzip web.zip
 
    systemctl enable nginx
    systemctl start nginx


}

install_v2scar(){
    yum install epel-release -y
    yum install -y wget git docker docker-compose
    git clone https://github.com/Ehco1996/v2scar.git
}

start_menu(){
    clear
    green " ===================================="
    green " 介绍：一键安装v2ray+ws+tls          "
    green " 系统：centos7                       "
    green " 作者：BBBob                         "
    green " ===================================="
    echo
    green " 1. 安装nginx+v2scar"
    green " 2. 配置nginx并安装ssl证书"
    green " 3. 仅安装nginx"
    green " 4. 仅安装v2scar"
    green " 5. 仅安装ssl证书"
    yellow " 0. 退出脚本"
    echo
    read -p "请输入数字:" num
    case "$num" in
    1)
    install_nginx
    install_domain 
    install_v2scar
    ;;
    2)
    install_domain
    ;;
    3)
    install_nginx
    ;;
    4)
    install_v2scar
    ;;
    5)
    install_ssl
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    red "请输入正确数字"
    sleep 2s
    start_menu
    ;;
    esac
}

start_menu


