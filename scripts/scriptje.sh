#!/bin/bash

# Create Mongodb-Prometheus-Exporter User
#kubectl exec mongos-router-0 -c mongos-container -- mongo --eval "db.getSiblingDB('admin').createUser({user: 'mongodb_exporter',pwd: 's3cr3tpassw0rd',roles:[{role:'clusterMonitor',db:'admin'},{ role: 'read', db: 'local' }],mechanisms:['SCRAM-SHA-1']})"




# Install helm
echo
echo "installing helm"
# installs helm with bash commands for easier command line integration
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
# add a service account within a namespace to segregate tiller
kubectl --namespace kube-system create sa tiller
# create a cluster role binding for tiller
kubectl create clusterrolebinding tiller \
    --clusterrole cluster-admin \
    --serviceaccount=kube-system:tiller

echo "initialize helm"
# initialized helm within the tiller service account
helm init --service-account tiller
# updates the repos for Helm repo integration
helm repo update


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
helm dependency update ../resources/helm/prometheus-operator
echo
echo
helm install ../resources/helm/prometheus-operator --name prometheus-operator --namespace monitoring


# Install MongoDB prometheus exporter
echo
echo
helm install ../resources/helm/prometheus-mongodb-exporter --name prometheus-mongodb-exporter
kubectl create -f ../resources/helm/prometheus-mongodb-exporter/svcmonitor.yaml

# Expose Grafana service
kubectl patch svc prometheus-operator-grafana -p '{"spec": {"type": "LoadBalancer"}}' --namespace monitoring

