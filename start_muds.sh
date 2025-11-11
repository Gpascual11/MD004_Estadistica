#!/bin/bash
# ======================================================================
# JUPYTERLAB DOCKER LAUNCHER (for MUDS project)
# - Starts or creates the container in the foreground.
# - Outputs connection URL for PyCharm.
# - **Stops the container when Ctrl+C is pressed.**
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

echo -e "${BLUE} Checking Docker status...${RESET}"
if ! command -v docker &> /dev/null; then
 echo -e "${YELLOW} Docker no est installat o al PATH.${RESET}"
 exit 1
fi

if ! systemctl is-active --quiet docker; then
 echo -e "${YELLOW} Iniciant servei Docker...${RESET}"
 sudo systemctl start docker
 sleep 2
fi

# --- PyCharm Connection Info ---
# Print the connection info before launching in foreground
BASE_URL="http://127.0.0.1:${HOST_PORT}"

echo -e "\n${GREEN}=====================================================${RESET}"
echo -e "${GREEN} Jupyter Server Actiu i Llest per a PyCharm!${RESET}"
echo -e "${GREEN}=====================================================${RESET}"
echo -e "${BLUE} Copia el segent URL (incls el token) per connectar:${RESET}"
echo -e "${YELLOW} ${BASE_URL}/?token=${JUPYTER_TOKEN}${RESET}"
echo -e "${GREEN}=====================================================${RESET}\n"


# --- Start or create container ---
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
  # Container exists. If running, stop it first.
  if [ -n "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo -e "${YELLOW} Aturant contenidor actiu per a mode foreground...${RESET}"
        docker stop $CONTAINER_NAME >/dev/null
    fi

    echo -e "${GREEN} Reiniciant i adjuntant contenidor existent (Ctrl+C per aturar)...${RESET}"
    # Start container attached to the current terminal
  docker start -a $CONTAINER_NAME

else
  echo -e "${GREEN} Creant contenidor nou i adjuntant (Ctrl+C per aturar)...${RESET}"
  # Create container and run it in the foreground (no -d flag)
  docker run \
    --restart unless-stopped \
    -p ${HOST_PORT}:8888 \
    --name ${CONTAINER_NAME} \
    -e JUPYTER_ENABLE_LAB=yes \
    -e JUPYTER_TOKEN=${JUPYTER_TOKEN} \
    -v ${LOCAL_PATH}:/home/jovyan/work \
    ${IMAGE}

fi

# Script will wait here, showing Docker logs, until you press Ctrl+C
echo -e "${YELLOW}\n Contenidor aturat. Adu.${RESET}"
