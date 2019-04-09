#!/bin/sh
##
# Script to deploy a Kubernetes project with a StatefulSet running a MongoDB Sharded Cluster, on GKE.
##

source ../resources/config

# Configure host VM using daemonset to disable hugepages
echo "Deploying GKE Daemon Set"
kubectl apply -f ../resources/hostvm-node-configurer-daemonset.yaml


# Define storage class for dynamically generated persistent volumes
kubectl apply -f ../resources/gce-ssd-storageclass.yaml


# Deploy a MongoDB ConfigDB Service ("Config Server Replica Set") using a Kubernetes StatefulSet
echo "Deploying GKE StatefulSet & Service for MongoDB Config Server Replica Set"
kubectl apply -f ../resources/mongodb-configdb-service.yaml


# Deploy each MongoDB Shard Service using a Kubernetes StatefulSet
echo "Deploying GKE StatefulSet & Service for each MongoDB Shard Replica Set"

for ((rs=1; rs<=$SHARD_REPLICA_SET; rs++)) do
  
  sed -e "s/shardX/shard${rs}/g; s/ShardX/Shard${rs}/g" ../resources/mongodb-maindb-service.yaml > /tmp/mongodb-maindb-service.yaml
  kubectl apply -f /tmp/mongodb-maindb-service.yaml

done


rm /tmp/mongodb-maindb-service.yaml


# Deploy some Mongos Routers using a Kubernetes StatefulSet
echo "Deploying GKE Deployment & Service for some Mongos Routers"
kubectl apply -f ../resources/mongodb-mongos-service.yaml


# Wait until the final mongod of each Shard + the ConfigDB has started properly
echo
echo "Waiting for all the shards and configdb containers to come up (`date`)..."
echo " (IGNORE any reported not found & connection errors)"
sleep 30
echo -n "  "
until kubectl --v=0 exec mongod-configdb-2 -c mongod-configdb-container -- mongo --quiet --eval 'db.getMongo()'; do
    sleep 5
    echo -n "  "
done


for ((rs=1; rs<=$SHARD_REPLICA_SET; rs++)) do
  echo -n "  "
  until kubectl --v=0 exec mongod-shard$rs-2 -c mongod-shard$rs-container -- mongo --quiet --eval 'db.getMongo()'; do
      sleep 5
      echo -n "  "
  done
done


echo "...shards & configdb containers are now running (`date`)"
echo


# Initialise the Config Server Replica Set and each Shard Replica Set
echo "Configuring Config Server's & each Shard's Replica Sets"


kubectl exec mongod-configdb-0 -c mongod-configdb-container -- mongo --eval 'rs.initiate({_id: "ConfigDBRepSet", version: 1, members: [ {_id: 0, host: "mongod-configdb-0.mongodb-configdb-service.default.svc.cluster.local:27017"}, {_id: 1, host: "mongod-configdb-1.mongodb-configdb-service.default.svc.cluster.local:27017"}, {_id: 2, host: "mongod-configdb-2.mongodb-configdb-service.default.svc.cluster.local:27017"} ]});'



for (( rs=1; rs<=$SHARD_REPLICA_SET; rs++ )) do
  ID=0

  SUBSTRING="{_id: \"Shard${rs}RepSet\", version: 1, members: [ {_id: 0, host: \"mongod-shard$rs-0.mongodb-shard$rs-service.default.svc.cluster.local:27017\"}, {_id: 1, host: \"mongod-shard$rs-1.mongodb-shard$rs-service.default.svc.cluster.local:27017\"}, {_id: 2, host: \"mongod-shard$rs-2.mongodb-shard$rs-service.default.svc.cluster.local:27017\"} ]}"

  DYNAMIC_STRING="kubectl exec mongod-shard$rs-0 -c mongod-shard$rs-container -- mongo --eval 'rs.initiate($SUBSTRING);'"
  
  ID=$((ID+1))

  eval $DYNAMIC_STRING
done

echo


# Wait for each MongoDB Shard's Replica Set + the ConfigDB Replica Set to each have a primary ready
echo "Waiting for all the MongoDB ConfigDB & Shards Replica Sets to initialise..."
kubectl exec mongod-configdb-0 -c mongod-configdb-container -- mongo --quiet --eval 'while (rs.status().hasOwnProperty("myState") && rs.status().myState != 1) { print("."); sleep(1000); };'

for ((rs=1; rs<=$SHARD_REPLICA_SET; rs++)) do
  kubectl exec mongod-shard$rs-0 -c mongod-shard$rs-container -- mongo --quiet --eval 'while (rs.status().hasOwnProperty("myState") && rs.status().myState != 1) { print("."); sleep(1000); };'
done

sleep 2 # Just a little more sleep to ensure everything is ready!
echo "...initialisation of the MongoDB Replica Sets completed"
echo


# Wait for the mongos to have started properly
echo "Waiting for the first mongos to come up (`date`)..."
echo " (IGNORE any reported not found & connection errors)"
echo -n "  "
until kubectl --v=0 exec mongos-router-0 -c mongos-container -- mongo --quiet --eval 'db.getMongo()'; do
    sleep 2
    echo -n "  "
done
echo "...first mongos is now running (`date`)"
echo


# Add Shards to the Configdb
echo "Configuring ConfigDB to be aware of the Shards"

POD_NAME=$(kubectl get pods | grep "router" | awk '{print $1;}')
# Moet maar op 1 router uitgevoerd worden?

for ((rs=1; rs<=$SHARD_REPLICA_SET; rs++)) do

  echo "Adding rs$rs to cluster"
  kubectl exec mongos-router-0 -c mongos-container -- mongo --eval "sh.addShard('Shard${rs}RepSet/mongod-shard${rs}-0.mongodb-shard${rs}-service.default.svc.cluster.local:27017');"

done


sleep 3


# Create the Admin User (this will automatically disable the localhost exception)
echo "Creating user: '${ADMIN_USER}'"
kubectl exec mongos-router-0 -c mongos-container -- mongo --eval "db.getSiblingDB('admin').createUser({user:'${ADMIN_USER}',pwd:'${ADMIN_PASSWORD}',roles:[{role:'root',db:'admin'}]});"
echo


# Create Mongodb-Prometheus-Exporter User
kubectl exec mongos-router-0 -c mongos-container -- mongo --eval "db.getSiblingDB('admin').createUser({user: 'mongodb_exporter',pwd: 's3cr3tpassw0rd',roles:[{role:'clusterMonitor',db:'admin'},{ role: 'read', db: 'local' }],mechanisms:['SCRAM-SHA-1']})"

# Install helm
./helm.sh

TILLERSTATUS=2

while [[ ${TILLERSTATUS} != "1" ]]
do

  if [ ${TILLERSTATUS} = 2 ]
  then
    printf "\nWaiting for tiller\n"
  fi

  TILLERSTATUS="$(kubectl get deployment tiller-deploy -n kube-system | tail -n +2 | awk '{print $5}')"

done
printf "\nTiller ready\n"

# Install Prometheus Operator
helm install -f ../monitoring/prometheus-operator-chart.yaml stable/prometheus-operator --name prometheus-operator

# Install MongoDB prometheus exporter
helm install -f ../monitoring/mongodb-exporter-chart.yaml --name prometheus-mongodb-exporter stable/prometheus-mongodb-exporter

# Print Summary State
kubectl get persistentvolumes
echo
kubectl get all 
echo
