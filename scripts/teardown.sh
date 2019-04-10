#!/bin/sh
##
# Script to remove/undepoy all project resources from GKE & GCE.
##

# Delete mongos stateful set + mongod stateful set + mongodb service + secrets + host vm configurer daemonset
kubectl delete statefulsets mongos-router
kubectl delete services mongos-router-service
kubectl delete statefulsets mongod-shard1
kubectl delete services mongodb-shard1-service
kubectl delete statefulsets mongod-shard2
kubectl delete services mongodb-shard2-service
kubectl delete statefulsets mongod-shard3
kubectl delete services mongodb-shard3-service
kubectl delete statefulsets mongod-configdb
kubectl delete services mongodb-configdb-service
kubectl delete daemonset hostvm-configurer
sleep 3

# Delete persistent volume claims
kubectl delete persistentvolumeclaims -l tier=maindb
kubectl delete persistentvolumeclaims -l tier=configdb
sleep 3

# Delete helm releases
helm ls --all --short | xargs -L1 helm delete --purge

# Cleanup prometheus operator
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
