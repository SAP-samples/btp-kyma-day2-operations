#!/usr/bin/env bash

log() {
  # Print the input text in yellow.
  local yellow='\033[0;33m'
  local no_color='\033[0m'
  echo -e "${yellow}$*${no_color}"
}

echo
log "███████  █████  ███████ ██    ██     ███████ ██████   █████  ███    ██  ██████ ██   ██ ██ ███████ ███████ ";
log "██      ██   ██ ██       ██  ██      ██      ██   ██ ██   ██ ████   ██ ██      ██   ██ ██ ██      ██      ";
log "█████   ███████ ███████   ████       █████   ██████  ███████ ██ ██  ██ ██      ███████ ██ ███████ █████   ";
log "██      ██   ██      ██    ██        ██      ██   ██ ██   ██ ██  ██ ██ ██      ██   ██ ██      ██ ██      ";
log "███████ ██   ██ ███████    ██        ██      ██   ██ ██   ██ ██   ████  ██████ ██   ██ ██ ███████ ███████ ";
echo
log "██████   █████  ██    ██     ██████  ";
log "██   ██ ██   ██  ██  ██           ██ ";
log "██   ██ ███████   ████        █████  ";
log "██   ██ ██   ██    ██        ██      ";
log "██████  ██   ██    ██        ███████ ";

echo
echo
echo

log "Setup of Operation Dashboard"

echo
echo
echo

programname=$0
DRY_RUN=false
COMPONENT_NUMBER=4
USE_ARTIFACTORY=false
COLUMNS=12
NAMESPACE="day2-operations"
configfile=easyfranchiseconfig.json

UI_PROJECT="day2-ui"
APPROUTER_PROJECT="day2-approuter"
OP_SERVICE_PROJECT="day2-service"

ELK_STACK_PROJECT="elk-stack"
DAY2_METRICS_PROJECT="day-2-observability-configuration"


UI_DOCKERFILE=./../day2-operations/deployment/docker/Dockerfile-day2-ui
APPROUTER_DOCKERFILE=./../day2-operations/deployment/docker/Dockerfile-day2-approuter

UI_HELM_CHART=./../day2-operations/deployment/helmCharts/day2-ui-chart
OP_HELM_CHART=./../day2-operations/deployment/helmCharts/day2-service-chart
APPROUTER_HELM_CHART=./../day2-operations/deployment/helmCharts/day2-approuter-chart

# for returning a single value:
declare retval=""

function usage {
    echo "usage: $programname [-d | --dry-run] [-h]"
    echo "  -d, --dry-run       ** optional **        print rendered yaml file without deploying to Kyma"    
    echo "  -h                  ** optional **        display help"
    exit 1
}

### read / write config file

write_config() {
  rawjson="{ \"subdomain-id\": \"$SUBDOMAIN\", \"cluster-domain\": \"$CLUSTER_DOMAIN\", \"kubeconfig-url\": \"$KUBECONFIG_URL\", \
   \"docker-email\": \"$DOCKER_EMAIL\", \"docker-id\": \"$DOCKER_ID\", \"docker-server\": \"$DOCKER_SERVER\", \"docker-repository\": \"$DOCKER_REPOSITORY\", \"docker-password\": \"$DOCKER_PASSWORD\", \
   \"db-sqlendpoint\": \"$DB_SQLENDPOINT\", \"db-admin\": \"$DB_ADMIN\", \"db-admin-password\": \"$DB_ADMIN_PASSWORD\"}"
  echo "$rawjson" | jq '.' >$configfile
}

read_config() {
  log "read configuration file"
  result=$(jq '.' $configfile)
  #echo "$result"
  SUBDOMAIN=$(jq -r '."subdomain-id"' <<< "${result}")
  CLUSTER_DOMAIN=$(jq -r '."cluster-domain"' <<< "${result}")
  KUBECONFIG_URL=$(jq -r '."kubeconfig-url"' <<< "${result}")

  #Docker Environment
  DOCKER_EMAIL=$(jq -r '."docker-email"' <<< "${result}")
  DOCKER_ID=$(jq -r '."docker-id"' <<< "${result}")
  DOCKER_SERVER=$(jq -r '."docker-server"' <<< "${result}")
  DOCKER_REPOSITORY=$(jq -r '."docker-repository"' <<< "${result}")
  DOCKER_PASSWORD=$(jq -r '."docker-password"' <<< "${result}")

  #HANA Cloud
  DB_SQLENDPOINT=$(jq -r '."db-sqlendpoint"' <<< "${result}")
  DB_ADMIN=$(jq -r '."db-admin"' <<< "${result}")
  DB_ADMIN_PASSWORD=$(jq -r '."db-admin-password"' <<< "${result}")  
}

function buildDeployOperationService() { 
  if [ "$USE_ARTIFACTORY" = "true" ]; then
    IMAGE_NAME="$DOCKER_REPOSITORY/$OP_SERVICE_PROJECT"
    IMAGE_TAG="$VERSION"
  else
    IMAGE_NAME="$DOCKER_REPOSITORY"
    IMAGE_TAG="$OP_SERVICE_PROJECT-$VERSION"    
  fi
  log "$OP_SERVICE_PROJECT Image Name: '$IMAGE_NAME:$IMAGE_TAG' "
  echo
  if [ "$DRY_RUN" = false ]; then
    log "$OP_SERVICE_PROJECT: Building new image"
    cd ./../day2-operations/source/day2-service
    ./mvnw spring-boot:build-image -DskipTests=true -Dspring-boot.build-image.imageName="$IMAGE_NAME:$IMAGE_TAG"    
    cd ./../../../setup
    echo
    log "$OP_SERVICE_PROJECT: Push new image"
    docker push "$IMAGE_NAME:$IMAGE_TAG"
    echo

    log "$OP_SERVICE_PROJECT: Deploy image"
    helm upgrade "$OP_SERVICE_PROJECT" "$OP_HELM_CHART" --install --namespace "$NAMESPACE" --set db.sqlendpoint="$DB_SQLENDPOINT" --set db.admin="$DB_ADMIN" --set db.password="$DB_ADMIN_PASSWORD" --set image.repository="$IMAGE_NAME" --set image.tag="$IMAGE_TAG" --wait --timeout 300s --atomic  
    echo
  else
    log "Dry Run: Skipping build"
    log "$PROJECT: Render Template"
    helm upgrade "$OP_SERVICE_PROJECT" "$OP_HELM_CHART" --install --namespace "$NAMESPACE" --set db.sqlendpoint="$DB_SQLENDPOINT" --set db.admin="$DB_ADMIN" --set db.password="$DB_ADMIN_PASSWORD" --set image.repository="$IMAGE_NAME" --set image.tag="$IMAGE_TAG" --wait --timeout 300s --atomic  --dry-run
    echo
  fi
}

function buildDeployUI() {
  if [ "$USE_ARTIFACTORY" = "true" ]; then
    IMAGE_NAME="$DOCKER_REPOSITORY/$UI_PROJECT"
    IMAGE_TAG="$VERSION"    
  else
    IMAGE_NAME="$DOCKER_REPOSITORY"
    IMAGE_TAG="$UI_PROJECT-$VERSION"    
  fi
  log "$UI_PROJECT Image Name: '$IMAGE_NAME:$IMAGE_TAG' "  
  echo
  if [ "$DRY_RUN" = false ]; then
    log "$UI_PROJECT: Building new image"
    docker build --no-cache=true --rm -t "$IMAGE_NAME:$IMAGE_TAG"  -f "$UI_DOCKERFILE" ./../..
    echo
    log "$UI_PROJECT: Push new image"
    docker push "$IMAGE_NAME:$IMAGE_TAG"
    echo
    
    log "$UI_PROJECT: Deploy image"
    helm upgrade "$UI_PROJECT" "$UI_HELM_CHART" --install --namespace "$NAMESPACE" --set image.repository="$IMAGE_NAME" --set image.tag="$IMAGE_TAG" --wait --timeout 300s --atomic
    echo
  else
    log "Dry Run: Skipping build"
    log "$UI_PROJECT: Render Template"
    helm upgrade "$PROJECT" "$UI_HELM_CHART" --install --namespace "$NAMESPACE" --set image.repository="$IMAGE_NAME" --set image.tag="$IMAGE_TAG" --wait --timeout 300s --atomic  --dry-run
    echo
  fi 

}

function buildDeployApprouter() {
  if [ "$USE_ARTIFACTORY" = "true" ]; then
    IMAGE_NAME="$DOCKER_REPOSITORY/$APPROUTER_PROJECT"
    IMAGE_TAG="$VERSION"    
  else
    IMAGE_NAME="$DOCKER_REPOSITORY"
    IMAGE_TAG="$APPROUTER_PROJECT-$VERSION"    
  fi
  log "$APPROUTER_PROJECT Image Name: '$IMAGE_NAME:$IMAGE_TAG' "  
  echo
  if [ "$DRY_RUN" = false ]; then
    log "$APPROUTER_PROJECT: Building new image"
    docker build --no-cache=true --rm -t "$IMAGE_NAME:$IMAGE_TAG"  -f "$APPROUTER_DOCKERFILE" ./../..
    echo
    log "$APPROUTER_PROJECT: Push new image"
    docker push "$IMAGE_NAME:$IMAGE_TAG"
    echo
    
    log "$APPROUTER_PROJECT: Deploy image"
    helm upgrade "$APPROUTER_PROJECT" "$APPROUTER_HELM_CHART" --install --namespace "$NAMESPACE" --set clusterdomain="$CLUSTER_DOMAIN" --set image.repository="$IMAGE_NAME" --set image.tag="$IMAGE_TAG" --wait --timeout 300s --atomic
    echo
  else
    log "Dry Run: Skipping build"
    log "$APPROUTER_PROJECT: Render Template"
    helm upgrade "$APPROUTER_PROJECT" "$APPROUTER_HELM_CHART" --install --namespace "$NAMESPACE" --set clusterdomain="$CLUSTER_DOMAIN" --set image.repository="$IMAGE_NAME" --set image.tag="$IMAGE_TAG" --wait --timeout 300s --atomic  --dry-run
    echo
  fi 
}

function deployElk() {
  if [ "$DRY_RUN" = false ]; then
    log "$ELK_STACK_PROJECT: Deploy Configuration"
    kubectl create -f https://download.elastic.co/downloads/eck/1.9.1/crds.yaml || true    
    kubectl apply -f https://download.elastic.co/downloads/eck/1.9.1/operator.yaml || true    
    kubectl apply -f ./../day2-operations/deployment/k8s/elk-stack/elastic_on_cloud.yaml || true    
    kubectl apply -f ./../day2-operations/deployment/k8s/elk-stack/elastic-expose.yaml || true    
    kubectl apply -f ./../day2-operations/deployment/k8s/elk-stack/kibana.yaml || true    
    kubectl apply -f ./../day2-operations/deployment/k8s/elk-stack/kibana-expose.yaml || true  
    kubectl apply -f ./../day2-operations/deployment/k8s/elk-stack/curator.yaml || true        
    cat ./../day2-operations/deployment/k8s/fluentbit.yaml | sed "s~<cluster-domain>~$CLUSTER_DOMAIN~g" | kubectl apply -f -    
    echo
  else
    log "Dry Run:"
    log "$ELK_STACK_PROJECT: Not supported in dry run"    
    echo
  fi  
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

query_parameters() {
 # BTP Environment
  log "Step 1.1 - BTP Environment"
  log "Enter Subdomain: " 
  read -r SUBDOMAIN

  log "Enter Cluster Domain: " 
  read -r CLUSTER_DOMAIN

  log "URL to Kubeconfig: " 
  read -r KUBECONFIG_URL
  echo ""

  # Docker Repository
  log "Step 1.2 - Docker Setup"
  log "Enter Docker Email: " 
  read -r DOCKER_EMAIL

  log "Enter Docker ID: " 
  read -r DOCKER_ID

  log "Enter Docker Password: " 
  read -s -r DOCKER_PASSWORD
  echo ""

  log "Enter Docker Server (e.g. https://index.docker.io/v1/ for Docker Hub): " 
  read -r DOCKER_SERVER

  log "Enter Docker Repository (e.g. for Docker Hub <docker account>/<repository name>): " 
  read -r DOCKER_REPOSITORY
  echo ""

  # HANA Cloud Setup
  log "Step 1.3 - HANA Cloud"
  log "Enter SQL Endpoint: " 
  read -r DB_SQLENDPOINT

  log "Enter DB Admin: " 
  read -r DB_ADMIN

  log "Enter DB Admin Password: " 
  read -s -r DB_ADMIN_PASSWORD
  echo ""
  echo ""

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


for i in "$@"; do
  case $i in        
    -d|--dry-run)
      DRY_RUN=true
      shift # past argument with no value
      ;;
    -a|--artifactory)
      USE_ARTIFACTORY=true
      shift # past argument with no value
      ;;
    -h|--help)
      usage
      ;;      
    *)
      # unknown option
      log "Error: Unknown argument ${i}"
      usage
      ;;
  esac
done

echo "================================================================================================="
echo "Step 1 - User Input"
echo "================================================================================================="
echo ""

FILE=./$configfile
if test -f "$FILE"; then
  continue_prompt_bool "Read parameters form config file easyfranchiseconfig.json?"
  doit=$retval
  echo "$doit"
  if [ "$doit" = true ]; then
    read_config
   else
    query_parameters
    
    continue_prompt_bool "Save Attributes as file (Please note that password will be stored in plain text!!!)?"
    doit=$retval
    echo "$doit"
    if [ "$doit" = true ]; then
      write_config
    fi        
  fi
 else
  query_parameters
  continue_prompt_bool "Save Attributes as file (Please note that password will be stored in plain text!!!)?"
    doit=$retval
    echo "$doit"
    if [ "$doit" = true ]; then
      write_config
    fi
fi

# Summary Step 1
echo ""
log "Step 1 - Summary"
echo ""

log "Deployment will be performed with the given attributes:"
echo ""
log "BTP Environment"
log "Subdomain: " "$SUBDOMAIN"
log "Kyma Cluster Domain: " "$CLUSTER_DOMAIN"
log "Kubeconfig Url: " "$KUBECONFIG_URL"
echo ""
log "Docker Environment"
log "Docker E-Mail: " "$DOCKER_EMAIL"
log "Docker ID: " "$DOCKER_ID"
log "Docker Password: ***********" 
log "Docker Server: " "$DOCKER_SERVER"
log "Docker Repository: " "$DOCKER_REPOSITORY"
echo ""
log "HANA Cloud"
log "SQL Endpoint: " "$DB_SQLENDPOINT"
log "DB Admin: " "$DB_ADMIN"
log "DB Admin Password: ********"
echo ""
echo ""
read -p "Continue with deployment? (y/n) " -n 1 -r
echo ""   # (optional) move to a new line

if [[ $REPLY =~ ^[Yy]$ ]]; then
    set -e #Cause script to break if an error occurs
    
    #Choose components to be deployed
    echo
    log "Choose component for deployment or deploy the whole application"
    declare -a arr="(Day2-Approuter Day2-Service Day2-UI ELK-Stack Full-Deployment)"    # must be quoted like this
    createmenu "${arr[@]}"
    COMPONENT_NUMBER="$retval"          

    log "================================================================================================="
    log "Step 2 - Check Kyma Environment"
    log "================================================================================================="
    echo ""
    log "Step 2.1 - Validate Cluster Access"
    log "Download Kubeconfig from $KUBECONFIG_URL"
    wget -q "$KUBECONFIG_URL" -O kubeconfig.yaml
    export KUBECONFIG="./kubeconfig.yaml"
    
    KYMA_CLUSTER_CONFIG="$(kubectl config view)"
    if [[ ${KYMA_CLUSTER_CONFIG} != *"$CLUSTER_DOMAIN"* ]];then
      log "Error: Check your configuration, current Kyma cluster does not match \033[1;31m $CLUSTER_DOMAIN \033[0m defined in provided .env file"
      exit 1
    fi
    log "Cluster Access successful"
    echo 

    log "================================================================================================="
    log "Step 3 - Prepare Cluster for Deployment"
    log "================================================================================================="
    echo ""

    log "Step 3.1 - Create Namepaces"
    if [ "$DRY_RUN" = false ]; then
      kubectl create namespace "$NAMESPACE" || true      
      kubectl create namespace "logging" || true
      kubectl create namespace "otel-system" || true

      kubectl label namespace "$NAMESPACE" istio-injection=enabled --overwrite || true
      kubectl label namespace "logging" istio-injection=enabled --overwrite || true
      kubectl label namespace "otel-system" istio-injection=enabled --overwrite || true      
    else 
      log "Skipped for Dry Run"
    fi

    echo
    log "Registry Secrets"

    if [ "$DRY_RUN" = true ]; then
      log "Skipped for Dry Run"
    else 
      kubectl -n "$NAMESPACE"  create secret docker-registry registry-secret --docker-server="$DOCKER_SERVER"  --docker-username="$DOCKER_ID" --docker-password="$DOCKER_PASSWORD" --docker-email="$DOCKER_EMAIL" || true
    fi
    echo 
    
    log "================================================================================================="
    log "Step 4 - Docker Setup"
    log "================================================================================================="
    echo ""
    docker login "$DOCKER_SERVER" -u "$DOCKER_ID" -p "$DOCKER_PASSWORD"
    echo

    log "================================================================================================="
    log "Step 5 - Component Build and Deploy"
    log "================================================================================================="
    echo ""
    
    VERSION=$(uuidgen)

    case $COMPONENT_NUMBER in
      1|5)	
      log "Step 5.1 - $APPROUTER_PROJECT: Building, Push and Deploy"
      #buildDeploy $PROJECT ./../easyfranchise/deployment/docker/Dockerfile-$PROJECT ./../easyfranchise/deployment/k8s/$PROJECT.yaml
      buildDeployApprouter
      ;;&    
      2|5)
      log "Step 5.2 - $OP_SERVICE_PROJECT: Building, Push and Deploy"
      buildDeployOperationService
      ;;&
      3|5)
      log "Step 5.3 - $UI_PROJECT: Building, Push and Deploy"
      buildDeployUI
      ;;&
      4|5)
      log "Step 5.4 - $ELK_STACK_PROJECT: Building, Push and Deploy"
      deployElk
      ;;     
    esac

    echo
    log "================================================================================================="
    log "Deployment Successful"
    log "================================================================================================="
    echo
fi 