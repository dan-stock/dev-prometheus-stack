#!/bin/bash
# set -x

# ## test seting the rules and alerts in prom
# PROM=$(oc get pods -n benchmark-operator|grep prometheus-server|awk '{print $1}')

# # oc rsync ./prometheus-recording_rules.yaml /etc/config/recording_rules.yml -c "$PROM"
# # oc rsync ./prometheus-alerting_rules.yaml /etc/config/alerting_rules.yml -c "$PROM"

# rsync --rsh='oc rsh' ./prometheus-recording_rules.yaml $PROM:/etc/config/recording_rules.yml

# echo "rsync --rsh='oc rsh' ./prometheus-recording_rules.yaml $PROM:/etc/config/recording_rules.yml"

# exit

## test the prometheus configuration and rules

helm uninstall prometheus -n benchmark-operator
# PROM=$(oc get pods -n benchmark-operator|grep prometheus-server|awk '{print $1}')
# PROM_ID=$(ps -ef |grep -E "$PROM&port-forward"|grep -v grc|awk '{print $2}')

# echo "$PROM_ID"
# ps -ef |grep port-forward

# exit

# kill -9 "$PROM_ID"

echo ""
helm install -f prometheus-config.yaml prometheus prometheus-community/prometheus -n benchmark-operator

###############################
## testing the run loop works

run_loop(){
    while : ; do
        echo ""
        oc get po
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

PROM=$(oc get pods -n benchmark-operator|grep prometheus-server|awk '{print $1}')
ps -ef |grep port-forward
echo $PROM

echo "kill port-forard first, then "
echo "kubectl port-forward -n benchmark-operator "$PROM" 9090 &"
echo "open http://localhost:9090/graph"


exit


helm upgrade --install -f prometheus-values.yaml prometheus prometheus-community/prometheus -n benchmark-operator


exit

#################

#!/bin/bash

# Define variables for the Pod name and namespace
POD_NAME=my-pod
NAMESPACE=my-namespace

# Get the list of instances in the Pod
INSTANCES=$(kubectl get pods -n ${NAMESPACE} -o json | jq -r ".items[] | .spec.containers[].name")

# Check if there are two instances running
if [ ${#INSTANCES} -eq 2 ]; then
    # Pod has two instances running, exit successfully
    echo "Pod has two instances running"
else
    # Pod does not have two instances running, exit with error message
    echo "Error: Pod does not have two instances running"
    kubectl get pods -n ${NAMESPACE} -o json | jq -r ".items[] | .spec.containers[].name"
fi

############
exit

for i in server:2:9090 exporter:1:9100 alertmanager:1:9093 grafana:1:3000; do
    echo $i
    POD=$($i |cut -f1 -d:)
    INSTANCE=$($i |cut -f1 -d:)
    PORT=$($i |cut -f1 -d:)
    echo "$POD $INSTANCE $PORT"
done

exit


# Set your OpenShift project and pod name
PROJECT_NAME="benchmark-operator"
POD_NAME=$(oc get pods -n benchmark-operator|grep prometheus-server|awk '{print $1}')
REQUIRED_INSTANCES=2
LOCAL_PORT=9090
REMOTE_PORT=8080

# Function to check if the required number of pod instances are running
check_pod_instances() {
    running_pods=$(oc get pods -n $PROJECT_NAME | grep $POD_NAME | grep "Running" | grep "$REQUIRED_INSTANCES/$REQUIRED_INSTANCES" | wc -l )
    echo $running_pods
    if [ $running_pods -eq 1 ]; then
        return 0
    else
        return 1
    fi
}

# Function to get the name of the first running pod
get_first_running_pod() {
    oc get pods -n $PROJECT_NAME | grep $POD_NAME | grep "Running" | awk '{print $1}' | head -n 1
}

# Main script
echo "Waiting for $REQUIRED_INSTANCES instances of $POD_NAME to be running..."

while true; do
    if check_pod_instances; then
        echo "$REQUIRED_INSTANCES instances of $POD_NAME are now running."
        break
    fi
    sleep 5
done

# Get the name of the first running pod
RUNNING_POD=$(get_first_running_pod)

if [ -z "$RUNNING_POD" ]; then
    echo "Error: Unable to find a running pod."
    exit 1
fi

echo "Starting port-forwarding for pod $RUNNING_POD..."
oc port-forward -n $PROJECT_NAME $RUNNING_POD $LOCAL_PORT:$REMOTE_PORT




#############
# #!/bin/bash
# set -x

# helm install grafana bitnami/grafana -n benchmark-operator

# GRAF=$(oc get pods -n benchmark-operator|grep grafana|awk '{print $1}')

# i=0
# while [ "$i" -lt 100 ] ;do
#     echo "$i"
#     i=$(( i + 1 ))
#     OK=$(oc get pods -n benchmark-operator "$GRAF" |grep 1/1)
#     if [ -z "$OK" ]; then
#         echo "try again"
#     else
#         echo "elasticsearch instance is running instances"
#         kubectl port-forward -n benchmark-operator "$GRAF" 3000 &
#         i=101
#     fi
#     sleep 10
# done

# kubectl exec --namespace benchmark-operator -it $(kubectl get pods --namespace benchmark-operator -l "app.kubernetes.io/name=grafana" -o jsonpath="{.items[0].metadata.name}") -- grafana cli admin reset-admin-password admin


#############
# helm install elasticsearch \
#     oci://registry-1.docker.io/bitnamicharts/elasticsearch \
#     --version 21.1.0 \
#     -n benchmark-operator \
#     --values elasticvalues.yaml

# ELASTICSEARCH_HTTP_PORT_NUMBER=9200
# ELASTICSEARCH_TRANSPORT_PORT_NUMBER=9300

# helm repo add elastic https://helm.elastic.co
# helm repo update

# helm install es-kb-quickstart elastic/eck-stack -n benchmark-operator

# helm install es-quickstart elastic/eck-stack -n elastic-stack --create-namespace \
#     --values https://raw.githubusercontent.com/elastic/cloud-on-k8s/2.13/deploy/eck-stack/examples/elasticsearch/hot-warm-cold.yaml \
#     --values https://raw.githubusercontent.com/elastic/cloud-on-k8s/2.13/deploy/eck-stack/examples/kibana/http-configuration.yaml

# i=0
# PROM=$(oc get pods -n benchmark-operator|grep prometheus-server|awk '{print $1}')
# echo "$PROM"

# while [ "$i" -lt 100 ] ;do
#     echo "$i"
#     i=$(( i + 1 ))
#     OK=$(oc get pods -n benchmark-operator "$PROM" |grep 2/2)
#     if [ -z "$OK" ]; then
#         echo "try again"
#     else
#         echo "OK"
#         exit
#     fi
#     sleep 10
# done



# while [ "$(kubectl get pods -l=app='activemq' -o jsonpath='{.items[*].status.containerStatuses[0].ready}')" != "true" ]; do
#    sleep 5
#    echo "Waiting for Broker to be ready."
# done