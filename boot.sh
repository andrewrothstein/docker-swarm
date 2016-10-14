#!/usr/bin/env bash
echo provisioning a consul kv store...
docker-machine create -d virtualbox kvstore
eval $(docker-machine env kvstore)
docker run \
       --name consul \
       --restart=always \
       -p 8400:8400 \
       -p 8500:8500 \
       -p 53:53/udp \
       -d \
       progrium/consul -server -bootstrap-expect 1 -ui-dir /ui

KVSTOREIP=$(docker-machine ip kvstore)
echo provisioning a swarm master...
docker-machine create -d virtualbox \
	       --swarm-master \
	       --swarm \
	       --swarm-discovery="consul://$KVSTOREIP:8500" \
	       --engine-opt="cluster-store=consul://$KVSTOREIP:8500" \
	       --engine-opt="cluster-advertise=eth0:2376" swarm-master

echo provisioning two swarm agents...
docker-machine create -d virtualbox \
	       --swarm \
	       --swarm-discovery="consul://$KVSTOREIP:8500" \
	       --engine-opt="cluster-store=consul://$KVSTOREIP:8500" \
	       --engine-opt="cluster-advertise=eth0:2376" swarm-node-1
docker-machine create -d virtualbox \
	       --swarm \
	       --swarm-discovery="consul://$KVSTOREIP:8500" \
	       --engine-opt="cluster-store=consul://$KVSTOREIP:8500" \
	       --engine-opt="cluster-advertise=eth0:2376" swarm-node-2

echo checking setup...
eval $(docker-machine env --swarm swarm-master)
docker info
