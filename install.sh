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
  --network=host \
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

mkdir -p /home/pi/docker_data/influxdb
docker run \
--rm -e INFLUXDB_DB=iobroker \
-e INFLUXDB_ADMIN_USER=admin \
-e INFLUXDB_ADMIN_PASSWORD="adminpassword" \
-e INFLUXDB_USER=iobroker \
-e INFLUXDB_USER_PASSWORD="password4iobrokerdb" \
-v /home/pi/docker_data/influxdb:/var/lib/influxdb2 influxdb /init-influxdb.sh #needs verification

docker run -d \
--name=influxdb \
--network=smart-home \
-p 8086:8086 \
--restart=always \
-v /home/pi/docker_data/influxdb:/var/lib/influxdb2 influxdb

mkdir -p /home/pi/docker_data/grafana
chown 472:472 /home/pi/docker_data/grafana #-R

docker run -d \
-p 3000:3000  \
--network=smart-home \
--restart=always --name=grafana \
-v /home/pi/docker_data/grafana:/var/lib/grafana grafana/grafana

docker run -d \
--net=host \
-p "53:53/tcp" \
-p "53:53/udp" \
-p "67:67/udp" \ # Only required if you are using Pi-hole as your DHCP server
-p "80:80/tcp" \
--cap-add=NET_ADMIN \
--restart=unless-stopped \
--name=pihole \
-e TZ='Europe/Berlin' \
-v /home/pi/docker_data/pihole/etc:/etc/pihole \
-v /home/pi/docker_data/pihole/dnsmasq.d:/etc/dnsmasq.d pihole/pihole:latest

