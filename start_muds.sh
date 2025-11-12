#!/bin/bash
# ======================================================================
# JUPYTERLAB DOCKER LAUNCHER (for MUDS project)
# - Starts or creates the container in the foreground.
# - Outputs connection URL.
# - **Stops the container when Ctrl+C is pressed.**
# - **Opens the URL in Brave Browser automatically.**
# - **FIXED: Forces R/Jupyter kernel to start in /home/jovyan/work.**
# ======================================================================

CONTAINER_NAME="muds_jupyter"
HOST_PORT=8888
LOCAL_PATH="/mnt/data/MUDS/EST/Practice"
IMAGE="jupyter/datascience-notebook"
JUPYTER_TOKEN="muds2025"
# Construct the full URL for JupyterLab access
TARGET_URL="http://127.0.0.1:${HOST_PORT}/lab?token=${JUPYTER_TOKEN}"

# --- Colors ---
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RESET="\033[0m"

echo -e "${BLUE} Checking Docker status...${RESET}"
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW} Docker no est instal·lat o al PATH.${RESET}"
    exit 1
fi

if ! systemctl is-active --quiet docker; then
    echo -e "${YELLOW} Iniciant servei Docker...${RESET}"
    sudo systemctl start docker
    sleep 2
fi

# CRITICAL FIX: Ensures the container is stopped when the script is interrupted (Ctrl+C)
trap "docker stop ${CONTAINER_NAME} >/dev/null 2>&1; echo -e \"\n${YELLOW} Contenidor aturat. Adéu.${RESET}\"" SIGINT SIGTERM EXIT

# --- Start or create container ---
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    # Container exists. If running, stop it first.
    if [ -n "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo -e "${YELLOW} Aturant contenidor actiu per a mode foreground...${RESET}"
        docker stop $CONTAINER_NAME >/dev/null
    fi

    echo -e "${GREEN} Reiniciant i adjuntant contenidor existent (Ctrl+C per aturar)...${RESET}"
    
    # Start container in detached mode temporarily to check for readiness
    docker start $CONTAINER_NAME >/dev/null

else
    echo -e "${GREEN} Creant contenidor nou...${RESET}"
    # Create container and run it in detached mode
    docker run \
        --restart unless-stopped \
        -p ${HOST_PORT}:8888 \
        --name ${CONTAINER_NAME} \
        -e JUPYTER_ENABLE_LAB=yes \
        -e JUPYTER_TOKEN=${JUPYTER_TOKEN} \
        -v ${LOCAL_PATH}:/home/jovyan/work \
        -w /home/jovyan/work \
        -d \
        ${IMAGE}
fi

# --- Wait and Launch Brave ---
echo -e "\n${BLUE} Esperant que el servidor Jupyter estigui operatiu a port ${HOST_PORT}...${RESET}"
MAX_ATTEMPTS=20
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s "http://127.0.0.1:${HOST_PORT}" > /dev/null; then
        echo -e "${GREEN} Servidor actiu! Obrint Brave...${RESET}"
        
        # Command to open the URL in Brave browser
        # Ensure 'brave' is in your system's PATH. You might need 'brave-browser' on some systems.
        if command -v brave &> /dev/null; then
            brave "$TARGET_URL" &
        elif command -v brave-browser &> /dev/null; then
            brave-browser "$TARGET_URL" &
        else
            echo -e "${YELLOW} 'brave' o 'brave-browser' no trobat. Obre manualment:${RESET}"
            echo -e "${YELLOW} ${TARGET_URL}${RESET}"
        fi
        
        break
    fi
    sleep 1
    ATTEMPT=$((ATTEMPT + 1))
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo -e "${YELLOW} No s'ha pogut verificar que el servidor Jupyter estigui actiu després de ${MAX_ATTEMPTS} segons.${RESET}"
fi

# Attach the running container to the current terminal (foreground mode)
echo -e "${GREEN} Adjuntant contenidor (Ctrl+C per aturar)...${RESET}"
docker attach $CONTAINER_NAME

# The trap command will execute before the script fully exits upon Ctrl+C.
# The final echo is technically never reached, but remains for clarity.
echo -e "${YELLOW}\n Contenidor aturat. Adéu.${RESET}"
