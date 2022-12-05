#!/bin/bash

init() 
{
    sudo apt-get update
    sudo apt-get install git -y
    sudo apt-get install openjdk-8-jdk -y
    sudo apt-get install maven -y
    mkdir -p ~/data
    mkdir -p ~/app/logs
}

killProcess()
{
    sudo kill -9 $(sudo lsof -t -i:8080)
}

cloneRepository() 
{
    cd ~/data || exit
    git clone https://github.com/spring-petclinic/spring-petclinic-reactjs.git
    cd ~/data/spring-petclinic-reactjs || exit
}

buildRepository()
{
    mvn clean package spring-boot:repackage
    cp ~/data/spring-petclinic-reactjs/target/petclinic.jar ~/app
}

runPackage()
{
    java -jar ~/app/petclinic.jar >> ~/app/logs/logfile.log &
}

init
cloneRepository
buildRepository
runPackage