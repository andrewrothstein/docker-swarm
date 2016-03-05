#!/usr/bin/env bash
echo provisioning 1 manager and 2 agents...
docker-machine create -d virtualbox manager
docker-machine create -d virtualbox agent1
docker-machine create -d virtualbox agent2
echo done provisioning

echo configuring swarm manager...
eval $(docker-machine env manager)
SWARM_TOKEN=$(docker run --rm swarm create)
echo swarm cluster token: $SWARM_TOKEN

SWARM_MANAGER_PORT=3376
echo booting swarm manager...
docker run -d \
       --name=swarm-manager \
       -p $SWARM_MANAGER_PORT:3376 \
       -t \
       -v /var/lib/boot2docker:/certs:ro \
       \
       swarm manage \
       -H 0.0.0.0:3376 \
       --tlsverify \
       --tlscacert=/certs/ca.pem \
       --tlscert=/certs/server.pem \
       --tlskey=/certs/server-key.pem \
       token://$SWARM_TOKEN

echo swarm manager boot as:
docker ps -a | fgrep swarm-manager

echo finished configuring manager

echo configuring agents...
for agent_id in manager agent1 agent2
do
    eval $(docker-machine env $agent_id)
    docker run \
	   -d \
	   --name=swarm-agent \
	   \
	   swarm join \
	   --addr=$(docker-machine ip $agent_id):2376 \
	   token://$SWARM_TOKEN
done
