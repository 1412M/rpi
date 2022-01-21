#!/bin/bash

apt update
apt upgrade

apt install docker-ce

usermod -aG docker pi

docker pull portainer/portainer-ce:latest
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

docker network create smart-home

mkdir -p /home/pi/docker_data
mkdir -p /home/pi/docker_data/iobroker

docker run -d \
  --network=smart-home \
  -p 8081:8081 \
  -p 8081:8081/udp \
  -p 8082:8082 \
  -p 8083:8083  \
  -p 1882:1882 \
  -p 8091:8091 \
  --hostname=iobroker \
  --restart=always  \
  --name iobroker  \
  -v /home/pi/docker_data/iobroker/:/opt/iobroker  \
  iobroker/iobroker -p
