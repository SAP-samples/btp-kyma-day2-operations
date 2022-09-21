#!/usr/bin/env bash

log() {
  # Print the input text in yellow.
  local yellow='\033[0;33m'
  local no_color='\033[0m'
  echo -e "${yellow}$*${no_color}"
}

continue_prompt_bool() {
  log
  read -p "$1 (y or yes to accept): " -r varname
  if [[ "$varname" != "y" ]] && [[ "$varname" != "yes" ]];
  then
    retval=false
  else
    retval=true
  fi
}

# user selection via passed array
# return ( index value)
createmenu() {
  #echo "Size of array: $#"
  #echo "$@"
  select option; do # in "$@" is the default
    if [ "$REPLY" -eq "$#" ];
    then
      #echo "Exiting..."
      break;
    elif [ 1 -le "$REPLY" ] && [ "$REPLY" -le $(($#-1)) ];
    then
      #echo "You selected $option which is option $REPLY"
      break;
    else
      echo "Incorrect Input: Select a number 1-$#"
    fi
  done
  retval=$REPLY  
}


read_automator_config() {  
  result=$(jq '.' /home/user/log/metadata_log.json)
  SUBDOMAIN=$(jq -r '."subdomain"' <<< "${result}")
  CLUSTER_DOMAIN=$(jq -r '."kymaDashboardUrl"' <<< "${result}")
  CLUSTER_DOMAIN="${CLUSTER_DOMAIN#*//console.}"
  KUBECONFIG_URL=$(jq -r '."kymaKubeConfigUrl"' <<< "${result}")
  DB_ADMIN="DBADMIN"
  DB_ADMIN_PASSWORD="$( echo "$result" | jq -r '.createdServiceInstances[] | select(.name == "hana-cloud") | .parameters.data.systempassword' 2> /dev/null)"
  
  DB_DASHBOARD="$( echo "$result" | jq -r '.createdServiceInstances[] | select(.name == "hana-cloud") | .statusResponse | ."dashboard url" ' 2> /dev/null)"  
  DB_HOST="${DB_DASHBOARD#*?host=}"
  DB_HOST=${DB_HOST/&component*}
  DB_PORT=${DB_DASHBOARD/*port=/}
  DB_SQLENDPOINT="$DB_HOST:$DB_PORT"
}

echo "####################################################################################################"
echo "# Step 1 - Summary of Application Environment"
echo "####################################################################################################"
echo ""
read_automator_config

log "Choose Deployment option, Variant 1 will deploy the application ready for the Mission. Variant 2 contains all the enhancements which will be introduced throughout the mission:"
declare -a arr="(Mission-Start Mission-End)"    # must be quoted like this
createmenu "${arr[@]}"
VARIANT_NUMBER="$retval"

case $VARIANT_NUMBER in
  1)	
    BTPSA_KYMA_IMAGE_TAG="main"
  ;;&    
  2)
    BTPSA_KYMA_IMAGE_TAG="endresult"
    log "Checkout endresult branch"
    cd /home/user/tutorial || exit
    git checkout endresult
  ;;          
esac

# Summary Step 1
echo
log "Deployment will be performed with the following attributes:"
echo ""
log "Selected Deployment Variant: $BTPSA_KYMA_IMAGE_TAG"
echo
log "BTP Environment"
log "Provider Subdomain: " "$SUBDOMAIN"
log "Kyma Cluster Domain: " "$CLUSTER_DOMAIN"
log "Kubeconfig Url: " "$KUBECONFIG_URL"
echo ""
log "HANA Cloud"
log "SQL Endpoint: " "$DB_SQLENDPOINT"
log "DB Admin: " "$DB_ADMIN"
log "DB Admin Password: ********"
echo ""
echo ""

read -p "Continue with deployment? (y/n) " -n 1 -r
echo 
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then

    log "####################################################################################################"
    log "# Step 2 - Deployment of Application Components"
    log "####################################################################################################"
    echo ""

    log "Step 2.1 - Create Namepaces"
    kubectl create namespace integration || true
    kubectl create namespace backend || true
    kubectl create namespace mock || true
    kubectl create namespace frontend || true

    kubectl label namespace integration istio-injection=enabled --overwrite || true
    kubectl label namespace backend istio-injection=enabled --overwrite || true
    kubectl label namespace mock istio-injection=enabled --overwrite || true
    kubectl label namespace frontend istio-injection=enabled --overwrite || true
    echo

    log "Step 2.2 - DB Secret: "
    cat /home/user/tutorial/code/easyfranchise/deployment/k8s/db-secret.yaml | sed "s~<db-sqlendpoint>~$DB_SQLENDPOINT~g" | sed "s~<db-admin>~$DB_ADMIN~g" | sed "s~<db-admin-password>~$DB_ADMIN_PASSWORD~g" | kubectl apply -f - || true
    echo

    log "Step 2.3 - Backend Configmap"
    kubectl apply -n backend -f /home/user/tutorial/code/easyfranchise/deployment/k8s/backend-configmap.yaml
    kubectl apply -n integration -f /home/user/tutorial/code/easyfranchise/deployment/k8s/backend-configmap.yaml      
    echo

    log "Step 2.4 - BTP Service Deployment"
    cat "/home/user/tutorial/code/easyfranchise/deployment/k8s/btp-services.yaml" | sed "s~<provider-subdomain>~$SUBDOMAIN~g" | sed "s~<cluster-domain>~$CLUSTER_DOMAIN~g" | kubectl apply -f -
    echo

    PROJECT=approuter
    log "Step 2.5 - Deploy $PROJECT"
    FULL_NAME=$BTPSA_KYMA_IMAGE_NAME_APPROUTER:$BTPSA_KYMA_IMAGE_TAG
    cat "/home/user/tutorial/code/easyfranchise/deployment/k8s/$PROJECT.yaml" | sed "s~<image-name>~$FULL_NAME~g" | sed "s~<provider-subdomain>~$SUBDOMAIN~g" | sed "s~<cluster-domain>~$CLUSTER_DOMAIN~g" | kubectl apply -f -

    PROJECT=db-service
    FULL_NAME=$BTPSA_KYMA_IMAGE_NAME_DB_SERVICE:$BTPSA_KYMA_IMAGE_TAG
    log "Step 2.6 - Deploy $PROJECT"
    cat "/home/user/tutorial/code/easyfranchise/deployment/k8s/$PROJECT.yaml" | sed "s~<image-name>~$FULL_NAME~g" | kubectl apply -f -

    PROJECT=bp-service
    FULL_NAME=$BTPSA_KYMA_IMAGE_NAME_BP_SERVICE:$BTPSA_KYMA_IMAGE_TAG
    log "Step 2.7 - Deploy $PROJECT"
    cat "/home/user/tutorial/code/easyfranchise/deployment/k8s/$PROJECT.yaml" | sed "s~<image-name>~$FULL_NAME~g" | kubectl apply -f -

    PROJECT=ef-service
    FULL_NAME=$BTPSA_KYMA_IMAGE_NAME_EF_SERVICE:$BTPSA_KYMA_IMAGE_TAG
    log "Step 2.8 - Deploy $PROJECT"
    cat "/home/user/tutorial/code/easyfranchise/deployment/k8s/$PROJECT.yaml" | sed "s~<image-name>~$FULL_NAME~g" | kubectl apply -f -

    PROJECT=broker
    FULL_NAME=$BTPSA_KYMA_IMAGE_NAME_BROKER:$BTPSA_KYMA_IMAGE_TAG
    log "Step 2.9 - Deploy $PROJECT"
    cat "/home/user/tutorial/code/easyfranchise/deployment/k8s/$PROJECT.yaml" | sed "s~<image-name>~$FULL_NAME~g" | kubectl apply -f -

    PROJECT=email-service
    FULL_NAME=$BTPSA_KYMA_IMAGE_NAME_EMAIL_SERVICE:$BTPSA_KYMA_IMAGE_TAG
    log "Step 2.10 - Deploy $PROJECT"
    cat "/home/user/tutorial/code/easyfranchise/deployment/k8s/$PROJECT.yaml" | sed "s~<image-name>~$FULL_NAME~g" | kubectl apply -f -

    PROJECT=ui
    FULL_NAME=$BTPSA_KYMA_IMAGE_NAME_UI:$BTPSA_KYMA_IMAGE_TAG
    log "Step 2.11 - Deploy $PROJECT"
    cat "/home/user/tutorial/code/easyfranchise/deployment/k8s/$PROJECT.yaml" | sed "s~<image-name>~$FULL_NAME~g" | kubectl apply -f -

    PROJECT=business-partner-mock
    FULL_NAME=$BTPSA_KYMA_IMAGE_NAME_BUSINESS_PARTNER_MOCK:$BTPSA_KYMA_IMAGE_TAG
    log "Step 2.12 - Deploy $PROJECT"
    cat "/home/user/tutorial/code/easyfranchise/deployment/k8s/$PROJECT.yaml" | sed "s~<image-name>~$FULL_NAME~g" | kubectl apply -f -


if [ "$BTPSA_KYMA_IMAGE_TAG" = "endresult" ]; then
  kubectl create namespace day2-operations || true
  kubectl label namespace day2-operations istio-injection=enabled --overwrite || true
  
  PROJECT=day2-approuter
  log "Step 2.13 - Deploy $PROJECT"
  helm upgrade "$PROJECT" "/home/user/tutorial/code/day2-operations/deployment/helmCharts/day2-approuter-chart" --install --namespace "day2-operations" --set clusterdomain="$CLUSTER_DOMAIN" --set image.repository="$BTPSA_KYMA_IMAGE_NAME_DAY2_APPROUTER" --set image.tag="$BTPSA_KYMA_IMAGE_TAG" --wait --timeout 90s --atomic

      PROJECT=day2-ui
      log "Step 2.14 - Deploy $PROJECT"
      helm upgrade "$PROJECT" "/home/user/tutorial/code/day2-operations/deployment/helmCharts/day2-ui-chart" --install --namespace "day2-operations" --set image.repository="$BTPSA_KYMA_IMAGE_NAME_DAY2_UI" --set image.tag="$BTPSA_KYMA_IMAGE_TAG" --wait --timeout 90s --atomic

      PROJECT=day2-service
      log "Step 2.15 - Deploy $PROJECT"
      helm upgrade "$PROJECT" "/home/user/tutorial/code/day2-operations/deployment/helmCharts/day2-service-chart" --install --namespace "day2-operations" --set db.sqlendpoint="$DB_SQLENDPOINT" --set db.admin="$DB_ADMIN" --set db.password="$DB_ADMIN_PASSWORD" --set image.repository="$BTPSA_KYMA_IMAGE_NAME_DAY2_SERVICE" --set image.tag="$BTPSA_KYMA_IMAGE_TAG" --wait --timeout 90s --atomic  
    fi
fi
echo
log "####################################################################################################"
log "# Deployment Successful"
log "####################################################################################################"
echo