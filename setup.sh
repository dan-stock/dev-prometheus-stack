#!/bin/bash

# todo
## set the configuration and rules for prometheus and alertmanager with notification to msteams

## setup the local dev environment to test the monitoring
kind delete cluster --name kind-benchmark
kind create cluster --config kind-cluster.yaml

## namespace: create and set config
kubectl create namespace monitoring
kubens monitoring
oc adm policy -n monitoring add-scc-to-user privileged -z monitoring
kubectl label ns monitoring pod-security.kubernetes.io/enforce=privileged

## set and update helm repos
# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# helm repo add elastic https://helm.elastic.co
# helm repo add geek-cookbook https://geek-cookbook.github.io/charts/
helm repo add prometheus-msteams https://prometheus-msteams.github.io/prometheus-msteams/
helm repo update

helm install msteams prometheus-msteams/prometheus-msteams -n monitoring

echo "Check if everything is running. Type return when everything is working."
run_loop(){
    while : ; do
        echo "#### push return when everything is ready"
        oc get po
        echo ""
        oc get svc
        echo ""
        oc get deployments
        sleep 10
        clear
        read -t 1 -n 1 input
        if [ $? = 0 ]; then
            echo "exiting loop"
            break
        fi
    done
}

run_loop

exit

NODE=$(oc get pods -n monitoring|grep prometheus-prometheus-node-exporter|awk '{print $1}')
ALERT=$(oc get pods -n monitoring|grep prometheus-alertmanager|awk '{print $1}')
GRAF=$(oc get pods -n monitoring|grep grafana|awk '{print $1}')

kubectl port-forward -n monitoring elasticsearch-master-0 9200 &
kubectl port-forward -n monitoring "$PROM" 9090 &
kubectl port-forward -n monitoring "$NODE" 9100 &
kubectl port-forward -n monitoring "$ALERT" 9093 &
kubectl port-forward -n monitoring "$GRAF" 3000 &

echo "# Prometheus      - http://localhost:9090/graph "
echo "# Node Exporter   - http://localhost:9100"
echo "# Alertmanager    - http://localhost:9093"
echo "# Grafana         - http://localhost:3000"
echo "Get the admin credentials for grafana with: "
echo "User: admin"
echo "Password: $(kubectl get secret grafana-admin --namespace monitoring -o jsonpath="{.data.GF_SECURITY_ADMIN_PASSWORD}" | base64 -d)"
echo "# Test metrics      - curl http://localhost:9090/metrics"

exit

## check and set port by hand until function is working.

# open all the port-forwarding
## 3000 = grafana
## 9090 = prometheus-server
## 9093 = alertmanager
## 9100 = prometheus-prometheus-node-exporter
## 9200 = elk

## ELASTICSEARCH_HTTP_PORT_NUMBER=9200
## ELASTICSEARCH_TRANSPORT_PORT_NUMBER=9300


# sleep 30

# # Function to check if the required number of pod instances are running
# check_pod_instances() {
#     running_pods=$(oc get pods -n $PROJECT_NAME | grep $POD_NAME | grep "Running" | grep "$REQUIRED_INSTANCES/$REQUIRED_INSTANCES" | wc -l )
#     echo $running_pods
#     if [ $running_pods -eq 1 ]; then
#         return 0
#     else
#         return 1
#     fi
# }

# # Function to get the name of the first running pod
# get_first_running_pod() {
#     oc get pods -n $PROJECT_NAME | grep $POD_NAME | grep "Running" | awk '{print $1}' | head -n 1
# }


PROM=$(oc get pods -n monitoring|grep prometheus-server|awk '{print $1}')
NODE=$(oc get pods -n monitoring|grep prometheus-prometheus-node-exporter|awk '{print $1}')
ALERT=$(oc get pods -n monitoring|grep prometheus-alertmanager|awk '{print $1}')
GRAF=$(oc get pods -n monitoring|grep grafana|awk '{print $1}')

kubectl port-forward -n monitoring elasticsearch-master-0 9200 &
kubectl port-forward -n monitoring "$PROM" 9090 &
kubectl port-forward -n monitoring "$NODE" 9100 &
kubectl port-forward -n monitoring "$ALERT" 9093 &
kubectl port-forward -n monitoring "$GRAF" 3000 &

for i in (server:2:9090 exporter:1:9100 alertmanager:1:9093 grafana:1:3000); do
    echo $i
done

i=0
while [ "$i" -lt 100 ] ;do
    echo "$i"
    i=$(( i + 1 ))
    OK=$(oc get pods -n monitoring "$PROM" |grep 2/2)
    if [ -z "$OK" ]; then
        echo "try again"
    else
        echo "$PROM is running 2 instances"
        kubectl port-forward -n monitoring "$PROM" 9090 &
        kubectl port-forward -n monitoring "$NODE" 9100 &
        kubectl port-forward -n monitoring "$ALERT" 9093 &
        i=101
    fi
    sleep 10
done

# i=0
# while [ "$i" -lt 100 ] ;do
#     echo "$i"
#     i=$(( i + 1 ))
#     OK=$(oc get pods -n monitoring "$GRAF" |grep 1/1)
#     if [ -z "$OK" ]; then
#         echo "try again"
#     else
#         echo "elasticsearch instance is running instances"
#         kubectl port-forward -n monitoring "$GRAF" 3000 &
#         i=101
#     fi
#     sleep 10
# done

i=0
while [ "$i" -lt 100 ] ;do
    echo "$i"
    i=$(( i + 1 ))
    OK=$(oc get pods -n monitoring elasticsearch-master-0 |grep 1/1)
    if [ -z "$OK" ]; then
        echo "try again"
    else
        echo "elasticsearch instance is running instances"
        kubectl port-forward -n monitoring elasticsearch-master-0 9200 &
        i=101
    fi
    sleep 10
done