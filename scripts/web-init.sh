#!/bin/bash

installNginx()
{
    nginx=stable # use nginx=development for latest development version
    sudo add-apt-repository --yes ppa:nginx/$nginx
    sudo apt update
    sudo apt install nginx -y
}

init() 
{
    installNginx
    sudo apt-get update
    sudo apt-get install git -y
    sudo apt-get install npm -y
    mkdir -p ~/data
}

cloneRepository() {
    cd ~/data || exit
    git clone https://github.com/spring-petclinic/spring-petclinic-reactjs.git
    cd spring-petclinic-reactjs/client || exit
}

buildRepository()
{
    npm install -f
    npm audit fix
    sed -i "s/localhost:8080/${endpoint}/g" ~/data/spring-petclinic-reactjs/client/webpack.config.prod.js
    npm run build:prod
}

writeNginxConf()
{
    cat << EOF | sudo tee /etc/nginx/sites-available/default
server {
    listen 80 default_server;

    location / {
        root   /usr/share/nginx/html;
        index  index.html;
        try_files \$uri \$uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://${app_lb_ip}:8080;
        proxy_http_version 1.1;
        proxy_redirect off;
    }
    
    error_page   500 502 503 504  /50x.html;
    
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF
    sudo service nginx reload
}

initWebserver()
{
    writeNginxConf
    sudo rm -rf  /usr/share/nginx/html/*
    sudo cp -r ~/data/spring-petclinic-reactjs/client/public/* /usr/share/nginx/html
    sudo systemctl restart nginx
}

init
cloneRepository
buildRepository
initWebserver