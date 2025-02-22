#!/bin/bash
set -e

# Remover possíveis caracteres BOM ou CRLF
sed -i $'1s/^\xEF\xBB\xBF//' "$0"
dos2unix "$0" 2>/dev/null || true

# Recebe os parâmetros da linha de comando
traefik="$1"
portainer="$2"
email="$3"

# Verifica se todos os parâmetros foram fornecidos
if [ -z "$traefik" ] || [ -z "$portainer" ] || [ -z "$email" ]; then
    echo "Erro: Todos os parâmetros são obrigatórios"
    echo "Uso: $0 <traefik_domain> <portainer_domain> <email>"
    exit 1
fi

# Cores
GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
CYAN='\e[36m'
NC='\e[0m'

# Função de limpeza
cleanup() {
    echo -e "\n${YELLOW}>> Limpando recursos temporários...${NC}"
    rm -f get-docker.sh
    rm -f temp_*
    echo -e "${GREEN}>> Limpeza concluída${NC}"
}

# Configurar trap para limpeza
trap cleanup EXIT

# Verificação de requisitos
check_requirements() {
    echo -e "\n${CYAN}>> Verificando sistema [INICIANDO]...${NC}"
    
    local free_space=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
    if [ "$free_space" -lt 10 ]; then
        echo -e "${RED}>> ERRO: Espaço em disco insuficiente [Mínimo: 10GB]${NC}"
        return 1
    fi
    
    local total_mem=$(free -g | awk 'NR==2 {print $2}')
    if [ $total_mem -lt 2 ]; then
        echo -e "${RED}>> ERRO: Memória RAM insuficiente [Mínimo: 2GB]${NC}"
        return 1
    fi
    
    if ! ping -c 1 google.com &> /dev/null; then
        echo -e "${RED}>> ERRO: Sem conexão com a internet${NC}"
        return 1
    fi
    
    echo -e "${GREEN}>> Sistema verificado [OK]${NC}"
    return 0
}

# Backup de instalação existente
backup_existing() {
    if [ -d ~/Portainer ]; then
        echo -e "${YELLOW}>> Realizando backup da instalação anterior...${NC}"
        backup_dir="portainer_backup_$(date +%Y%m%d_%H%M%S)"
        mv ~/Portainer ~/$backup_dir
        echo -e "${GREEN}>> Backup concluído em ~/$backup_dir${NC}"
    fi
}

# Função para resetar instalação
reset_installation() {
    echo -e "\n${YELLOW}>> Iniciando reset do sistema...${NC}"
    
    echo -e "${CYAN}>> Removendo containers...${NC}"
    docker stop $(docker ps -aq) 2>/dev/null
    docker rm $(docker ps -aq) 2>/dev/null
    
    echo -e "${CYAN}>> Removendo volumes...${NC}"
    docker volume rm $(docker volume ls -q) 2>/dev/null
    
    echo -e "${CYAN}>> Removendo redes...${NC}"
    docker network rm $(docker network ls -q) 2>/dev/null
    
    echo -e "${CYAN}>> Removendo imagens...${NC}"
    docker rmi $(docker images -aq) 2>/dev/null
    
    echo -e "${CYAN}>> Removendo Docker...${NC}"
    sudo apt-get remove docker docker-engine docker.io containerd runc -y 2>/dev/null
    sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y 2>/dev/null
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    
    echo -e "${CYAN}>> Removendo diretório Portainer...${NC}"
    rm -rf ~/Portainer
    
    echo -e "${GREEN}>> Reset concluído com sucesso!${NC}"
    echo -e "${YELLOW}>> Nova instalação pronta para iniciar.${NC}"
    cd /root
    sleep 3
    show_welcome
    return 0
}

# Novo layout tecnológico para boas-vindas
show_welcome() {
    clear
    echo -e "${CYAN}
    ╔════════════════════════════════════════════════════╗
    ║                                                    ║
    ║  [SYSTEM BOOT] Portainer Installation Interface    ║
    ║                                                    ║
    ╚════════════════════════════════════════════════════╝
    ${GREEN}
    >> Developed by: Maicon Bartoski
    >> Version: 2.0
    >> Initializing deployment sequence...
    
    [FEATURES]
    - Portainer CE Deployment
    - Traefik Proxy Integration
    - Automated SSL Configuration
    - Secure System Setup
    ${NC}"
    
    echo -e "\n${YELLOW}>> Select an option:${NC}"
    echo -e "${GREEN}  [1] Deploy Portainer${NC}"
    echo -e "${RED}  [2] Reset existing installation${NC}"
    echo -e "${YELLOW}  [3] Exit system${NC}"
    
    read -p ">> Input your choice [1-3]: " choice
    
    case $choice in
        1)
            echo -e "\n${GREEN}>> Starting Portainer deployment...${NC}"
            sleep 2
            ;;
        2)
            echo -e "\n${YELLOW}>> WARNING: This will erase all previous installations.${NC}"
            read -p ">> Confirm reset? [y/n]: " confirm
            if [[ $confirm == [yY] ]]; then
                reset_installation
            else
                echo -e "\n${YELLOW}>> Operation aborted.${NC}"
                exit 0
            fi
            ;;
        3)
            echo -e "\n${YELLOW}>> Shutting down interface...${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}>> ERROR: Invalid selection!${NC}"
            exit 1
            ;;
    esac
}

# Novo banner de instalação tecnológico
install_banner() {
    clear
    echo -e "${CYAN}
    ╔════════════════════════════════════════════════════╗
    ║  [DEPLOYMENT MODULE] Portainer + Traefik           ║
    ║  Powered by Maicon Bartoski                        ║
    ╚════════════════════════════════════════════════════╝${NC}"
}

# Função para mostrar spinner futurista
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${CYAN}[%c]${NC} Processing... " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
    done
    printf "               \b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
}

# Função para mostrar progresso tecnológico
show_progress() {
    local step=$1
    local message=$2
    local total=5
    local percent=$((step * 100 / total))
    local completed=$((percent / 4))
    
    echo -ne "${GREEN}>> Step ${YELLOW}$step/$total ${CYAN}["
    for ((i=0; i<25; i++)); do
        if [ $i -lt $completed ]; then
            echo -ne "█"
        else
            echo -ne " "
        fi
    done
    echo -e "] ${percent}% - ${GREEN}$message${NC}"
}

# Novo logo tecnológico
logo() {
    clear
    echo -e "${CYAN}
    ╔════════════════════════════════════════════════════╗
    ║  [SYSTEM CORE] Portainer Deployment                ║
    ║  Engineered by Maicon Bartoski                     ║
    ╚════════════════════════════════════════════════════╝
    ${GREEN}10101010  [RUNNING]  01010101${NC}"
    echo ""
}

# Novo logo do Portainer
portainer_logo() {
    clear
    echo -e "${CYAN}
    ╔════════════════════════════════════════════════════╗
    ║  [CONTAINER SYSTEM] Portainer CE                   ║
    ║  Deployed by Maicon Bartoski                       ║
    ╚════════════════════════════════════════════════════╝
    ${GREEN}01010101  [ACTIVE]  10101010${NC}"
    echo ""
}

desc_ver() {
    echo -e "${YELLOW}>> Recommended OS: Ubuntu ${GREEN}20.04${NC}"
    echo ""
}

# Mostrar boas-vindas
show_welcome

# Verificar requisitos
if ! check_requirements; then
    echo -e "${RED}>> ERROR: System requirements not met. Deployment aborted.${NC}"
    exit 1
fi

# Fazer backup se necessário
backup_existing

clear
logo
echo ">> Initializing system checks..."
sleep 5

# Verifica se está usando Ubuntu 20.04
if ! grep -q 'Ubuntu 20.04' /etc/os-release; then
    logo
    desc_ver
    sleep 5
    clear
    logo
fi

# Verifica se o usuário é root
if [ "$(id -u)" -ne 0 ]; then
    echo ">> This script requires root privileges. Switching to sudo..."
    sudo su
fi

# Verifica se o usuário está no diretório /root/
if [ "$PWD" != "/root" ]; then
    echo ">> Changing to /root/ directory..."
    cd /root || exit
fi

#-------------------------------------------

logo

## Fazendo upgrade
show_progress 1 "Updating system core"
sudo apt upgrade -y > /dev/null 2>&1 &
spinner $!
if [ $? -eq 0 ]; then
    echo -e "${GREEN}>> System updated successfully${NC}"
else
    echo -e "${RED}>> ERROR: Failed to update system${NC}"
fi

echo ""

## Instalando Sudo
show_progress 2 "Installing core dependencies"
apt install sudo -y > /dev/null 2>&1 &
spinner $!
if [ $? -eq 0 ]; then
    echo -e "${GREEN}>> Dependencies installed successfully${NC}"
else
    echo -e "${RED}>> ERROR: Failed to install dependencies${NC}"
fi

echo ""

## Instalando apt-utils
show_progress 3 "Configuring apt-utils"
sudo apt-get install -y apt-utils > /dev/null 2>&1 &
spinner $!
if [ $? -eq 0 ]; then
    echo -e "${GREEN}>> Apt-utils configured successfully${NC}"
else
    echo -e "${RED}>> ERROR: Failed to configure apt-utils${NC}"
fi

echo ""

## Fazendo update
show_progress 4 "Running system update"
sudo apt update > /dev/null 2>&1 &
spinner $!
if [ $? -eq 0 ]; then
    echo -e "${GREEN}>> Update completed successfully${NC}"
else
    echo -e "${RED}>> ERROR: Failed to run update${NC}"
fi

echo ""

## Fazendo upgrade
show_progress 5 "Finalizing system upgrade"
sudo apt upgrade -y > /dev/null 2>&1 &
spinner $!
if [ $? -eq 0 ]; then
    echo -e "${GREEN}>> Upgrade completed successfully${NC}"
else
    echo -e "${RED}>> ERROR: Failed to upgrade system${NC}"
fi

sudo apt update
sudo apt upgrade -y

# Função para mostrar um banner colorido tecnológico
function show_banner() {
    logo
    echo -e "${CYAN}>> System preparation in progress...${NC}"
    echo -e "${GREEN}01010101  [LOADING REQUIREMENTS]  10101010${NC}"
}

# Função para verificar se o Portainer está acessível
function wait_for_portainer() {
    echo ">> Awaiting Portainer initialization..."
    PORTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' portainer)
    echo ">> Testing connection to $PORTAINER_IP..."
    
    TIMEOUT=60
    SECONDS_WAITED=0
    
    while ! curl -s http://$PORTAINER_IP:9000 >/dev/null; do
        echo -n "."
        sleep 5
        SECONDS_WAITED=$((SECONDS_WAITED + 5))
        if [ $SECONDS_WAITED -ge $TIMEOUT ]; then
            echo ""
            echo ">> ERROR: Portainer connection timeout exceeded."
            exit 1
        fi
    done
    echo ""
    echo ">> Portainer online."
    return 0
}

# Função para inicializar a conta de administrador
function initialize_admin_account() {
    echo ">> Configuring admin user for Portainer..."
    PORTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' portainer)
    PORTAINER_URL="http://$PORTAINER_IP:9000"
    INITIALIZE=$(curl -s -X POST "$PORTAINER_URL/api/users/admin/init" -H "Content-Type: application/json" -d "{\"username\": \"$email\", \"password\": \"$key\"}")
    echo ">> Admin setup: $INITIALIZE"
}

# Função para criar uma stack via API
function create_stack() {
    if [ -z "$1" ]; then
        echo ">> Usage: create_stack <file_path>"
        return 1
    fi
    local filepath="$1"
    local filename=$(basename "$filepath")
    echo ">> Deploying stack $filename..."
    PORTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' portainer)
    PORTAINER_URL="http://$PORTAINER_IP:9000"
    JWT_TOKEN=$(curl -s -X POST "$PORTAINER_URL/api/auth" -H "Content-Type: application/json" -d "{\"username\": \"$email\", \"password\": \"$key\"}" | jq -r .jwt)
    if [ -z "$JWT_TOKEN" ]; then
        echo ">> ERROR: Authentication token retrieval failed."
        return 1
        exit 1
    fi
    curl -s -X POST "$PORTAINER_URL/api/stacks/create/standalone/file?endpointId=1" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: multipart/form-data" \
        -F "Name=$filename" \
        -F "file=@${filepath}"
    if [ $? -ne 0 ]; then
        echo ">> ERROR: Stack creation failed."
        return 1
        exit 1
    else
        echo ">> Stack deployed successfully!"
        return 0
    fi
}

# Função para gerar senha htpasswd
generate_htpasswd() {
    local username=$1
    local password=$2
    if ! command -v htpasswd &> /dev/null; then
        apt-get update > /dev/null 2>&1
        apt-get install -y apache2-utils > /dev/null 2>&1
    fi
    local temp_file=$(mktemp)
    htpasswd -nb -B $username $password > "$temp_file"
    local hash=$(cat "$temp_file")
    rm "$temp_file"
    hash=$(echo "$hash" | sed 's/\$/\$\$/g')
    echo "$hash"
}

# Mostrar banner inicial
clear
show_banner
echo ""

# Gere uma senha aleatória
show_progress 4 "Generating security key..."
key=$(openssl rand -hex 16)

# Gerar credenciais do Traefik
traefik_user="admin"
traefik_pass="admin"
htpasswd=$(generate_htpasswd "$traefik_user" "$traefik_pass")

# Verificação de dados
clear
echo -e "${CYAN}>> Deployment Configuration Summary:${NC}"
echo -e "${YELLOW}  Traefik Domain:${NC} $traefik"
echo -e "${YELLOW}  Portainer Domain:${NC} $portainer"
echo -e "${YELLOW}  Email:${NC} $email"
echo ""
echo -e "${GREEN}>> Launching deployment sequence...${NC}"
sleep 2

clear
###########################
# INSTALANDO DEPENDENCIAS #
###########################
install_banner
echo -e "\n${GREEN}>> Starting Installation Process...${NC}\n"

show_progress 1 "Updating system"
(apt update -y && apt upgrade -y) > /dev/null 2>&1 &
spinner $!
echo -e "${GREEN}>> System updated${NC}\n"

show_progress 2 "Installing dependencies"
apt install -y curl jq apache2-utils > /dev/null 2>&1 &
spinner $!
echo -e "${GREEN}>> Dependencies installed${NC}\n"

show_progress 3 "Installing Docker engine"
curl -fsSL https://get.docker.com -o get-docker.sh > /dev/null 2>&1
sh get-docker.sh > /dev/null 2>&1 &
spinner $!
echo -e "${GREEN}>> Docker installed${NC}\n"

show_progress 4 "Preparing environment"
mkdir -p ~/Portainer && cd ~/Portainer
echo -e "${GREEN}>> Environment ready${NC}\n"

show_progress 5 "Configuring system"
echo -e "${GREEN}>> Configuration complete${NC}\n"

###########################
# CRIANDO DOCKER-COMPOSE.YML #
###########################
show_progress 1 "Generating configuration file"
cat >docker-compose.yml <<EOM
services:
  traefik:
    container_name: traefik
    image: "traefik:latest"
    restart: always
    command:
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --api.insecure=true
      - --api.dashboard=true
      - --providers.docker
      - --log.level=ERROR
      - --certificatesresolvers.leresolver.acme.httpchallenge=true
      - --certificatesresolvers.leresolver.acme.email=$email
      - --certificatesresolvers.leresolver.acme.storage=./acme.json
      - --certificatesresolvers.leresolver.acme.httpchallenge.entrypoint=web
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./acme.json:/acme.json"
    labels:
      - "traefik.http.routers.http-catchall.rule=hostregexp(\`{host:.+}\`)"
      - "traefik.http.routers.http-catchall.entrypoints=web"
      - "traefik.http.routers.http-catchall.middlewares=redirect-to-https"
      - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
      - "traefik.http.routers.traefik-dashboard.rule=Host(\`$traefik\`)"
      - "traefik.http.routers.traefik-dashboard.entrypoints=websecure"
      - "traefik.http.routers.traefik-dashboard.service=api@internal"
      - "traefik.http.routers.traefik-dashboard.tls.certresolver=leresolver"
      - "traefik.http.middlewares.traefik-auth.basicauth.users=$htpasswd"
      - "traefik.http.routers.traefik-dashboard.middlewares=traefik-auth"
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    command: -H unix:///var/run/docker.sock
    restart: always
    environment:
      - ADMIN_USERNAME=$email
      - ADMIN_PASSWORD=$key
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=Host(\`$portainer\`)"
      - "traefik.http.routers.frontend.entrypoints=websecure"
      - "traefik.http.services.frontend.loadbalancer.server.port=9000"
      - "traefik.http.routers.frontend.service=frontend"
      - "traefik.http.routers.frontend.tls.certresolver=leresolver"
volumes:
  portainer_data:
EOM
echo -e "${GREEN}>> Configuration file created${NC}\n"

###########################
# CERTIFICADOS LETSENCRYPT #
###########################
show_progress 2 "Configuring SSL certificates"
touch acme.json
chmod 600 acme.json
echo -e "${GREEN}>> SSL certificates configured${NC}\n"

###########################
# INICIANDO CONTAINERS #
###########################
show_progress 3 "Launching containers"
docker compose up -d > /dev/null 2>&1 &
spinner $!
echo -e "${GREEN}>> Containers launched${NC}\n"

# Espera o Portainer estar acessível
show_progress 4 "Awaiting Portainer startup"
wait_for_portainer
echo -e "${GREEN}>> Portainer online${NC}\n"

# Iniciar usuário do Portainer
show_progress 5 "Setting up Portainer user"
initialize_admin_account
echo -e "${GREEN}>> User configured${NC}\n"

## Mensagem de conclusão tecnológica
clear
logo
echo -e "${GREEN}>> DEPLOYMENT COMPLETE [SUCCESS]${NC}"
echo -e "\n${CYAN}>> Portainer Access Credentials:${NC}"
echo -e "${YELLOW}  URL:${NC} https://$portainer"
echo -e "${YELLOW}  User:${NC} $email"
echo -e "${YELLOW}  Password:${NC} $key"
echo -e "\n${CYAN}>> Traefik Access Credentials:${NC}"
echo -e "${YELLOW}  URL:${NC} https://$traefik"
echo -e "${YELLOW}  User:${NC} $traefik_user"
echo -e "${YELLOW}  Password:${NC} $traefik_pass"
echo -e "\n${GREEN}>> System fully operational. Deployment by Maicon Bartoski.${NC}"
