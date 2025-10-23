#!/bin/bash
# ======================================================================
#  JUPYTERLAB DOCKER LAUNCHER (for MUDS project)
#  - Starts or creates the container if needed
#  - Opens Brave automatically when ready
# ======================================================================

CONTAINER_NAME="muds_jupyter"
HOST_PORT=8888
LOCAL_PATH="/mnt/data/MUDS/EST/Practice"
IMAGE="jupyter/datascience-notebook"
URL="http://127.0.0.1:${HOST_PORT}/lab"
JUPYTER_TOKEN="muds2025"

# --- Colors ---
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RESET="\033[0m"

echo -e "${BLUE}🔍 Checking Docker status...${RESET}"
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker no està instal·lat o al PATH.${RESET}"
    exit 1
fi

if ! systemctl is-active --quiet docker; then
    echo -e "${YELLOW}⏳ Iniciant servei Docker...${RESET}"
    sudo systemctl start docker
    sleep 2
fi

# --- Start or create container ---
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    if [ -z "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo -e "${GREEN}▶️  Reiniciant contenidor existent...${RESET}"
        docker start $CONTAINER_NAME >/dev/null
    else
        echo -e "${GREEN}🟢 Contenidor ja actiu.${RESET}"
    fi
else
    echo -e "${GREEN}🚀 Creant contenidor nou...${RESET}"
    docker run -d \
	--restart unless-stopped \
        -p ${HOST_PORT}:8888 \
        --name ${CONTAINER_NAME} \
        -e JUPYTER_ENABLE_LAB=yes \
        -e JUPYTER_TOKEN=${JUPYTER_TOKEN} \
        -v ${LOCAL_PATH}:/home/jovyan/work \
	-v /home/gerardpf/.jupyter_theme:/home/jovyan/.jupyter/lab/user-settings/@jupyterlab/apputils-extension \
        ${IMAGE} >/dev/null
fi

# --- Espera que estigui "healthy" ---
echo -e "${BLUE}⏳ Esperant que Jupyter estigui llest...${RESET}"
for i in {1..20}; do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null)
    if [ "$STATUS" == "healthy" ]; then
        break
    fi
    sleep 1
done

# --- Open Brave ---
echo -e "${GREEN}🌐 Obrint JupyterLab a: ${URL}${RESET}"
nohup brave "$URL" >/dev/null 2>&1 &

echo -e "${GREEN}✅ JupyterLab actiu i funcionant a $URL${RESET}"
