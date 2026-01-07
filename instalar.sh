#!/bin/bash
# Script Instalador Adaptado para RicardoB3/Ultimate-VPS
# Soporte para carpetas 'gerador' e 'Install'
# Compatible con Ubuntu 20.04 y 22.04

# --- TUS DATOS DE GITHUB ---
USUARIO="RicardoB3"
REPO="Ultimate-VPS"
RAMA="master"
# ---------------------------

URL_RAW="https://raw.githubusercontent.com/${USUARIO}/${REPO}/${RAMA}"
DIR_BASE="/etc/newadm"
DIR_USER="${DIR_BASE}/ger-user"
DIR_INST="/etc/ger-inst"
DIR_HERR="/etc/ger-frm"

# Colores
msg () {
    BRAN='\033[1;37m' && VERMELHO='\e[31m' && VERDE='\e[32m' && AMARELO='\e[33m'
    AZUL='\e[34m' && MAGENTA='\e[35m' && MAG='\033[1;36m' && NEGRITO='\e[1m' && SEMCOR='\e[0m'
    case $1 in
        -ne) echo -ne "${VERMELHO}${NEGRITO}${2}${SEMCOR}";;
        -ama) echo -e "${AMARELO}${NEGRITO}${2}${SEMCOR}";;
        -verm) echo -e "${AMARELO}${NEGRITO}[!] ${VERMELHO}${2}${SEMCOR}";;
        -azu) echo -e "${MAG}${NEGRITO}${2}${SEMCOR}";;
        -verd) echo -e "${VERDE}${NEGRITO}${2}${SEMCOR}";;
        -bar) echo -e "${AZUL}${NEGRITO}====================================================${SEMCOR}";;
    esac
}

# 1. Verificación de Root
[[ $EUID -ne 0 ]] && msg -verm "Error: Ejecuta como root" && exit 1

# 2. Instalación de Dependencias (Ubuntu 20/22 Fix)
preparar_vps () {
    clear
    msg -bar
    msg -ama "ACTUALIZANDO SISTEMA Y DEPENDENCIAS..."
    
    # Liberar apt si está bloqueado
    rm -rf /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
    
    apt-get update -y > /dev/null 2>&1
    
    # Paquetes esenciales + Fix de Python para scripts antiguos
    PAQUETES="jq bc screen curl ufw unzip zip net-tools nano python3 python3-pip python-is-python3 cron apache2 at"
    
    for paq in $PAQUETES; do
        [[ $(dpkg --get-selections|grep -w "$paq"|head -1) ]] || apt-get install $paq -y &>/dev/null
        echo -ne "\033[1;32m [OK] $paq \033[0m"
    done
    echo ""

    # Mover Apache al puerto 81
    if [[ -f /etc/apache2/ports.conf ]]; then
        sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf
        service apache2 restart > /dev/null 2>&1
    fi
}

# 3. Estructura de Directorios
crear_directorios () {
    mkdir -p ${DIR_BASE}
    mkdir -p ${DIR_USER}
    mkdir -p ${DIR_INST}
    mkdir -p ${DIR_HERR}
}

# 4. Descarga Inteligente (Soporte para carpetas)
descargar_archivos () {
    msg -bar
    msg -ama "DESCARGANDO ARCHIVOS DESDE GITHUB..."
    
    # A) Descargar archivo de traducción desde carpeta 'Install'
    msg -azu "Descargando traducciones..."
    wget -O /usr/bin/trans ${URL_RAW}/Install/trans &>/dev/null
    chmod +x /usr/bin/trans

    # B) Descargar la lista 'GERADOR' desde carpeta 'gerador'
    msg -azu "Obteniendo lista de scripts..."
    wget -O ${DIR_BASE}/lista-arq ${URL_RAW}/gerador/GERADOR &>/dev/null
    
    if [[ ! -s ${DIR_BASE}/lista-arq ]]; then
        msg -verm "ERROR: No se encontró el archivo 'gerador/GERADOR' en tu GitHub."
        exit 1
    fi

    # C) Bucle de descarga desde carpeta 'gerador'
    for arqx in $(cat ${DIR_BASE}/lista-arq); do
        msg -azu "Descargando: $arqx"
        
        # Descarga desde la carpeta /gerador/
        wget -O ${DIR_BASE}/${arqx} ${URL_RAW}/gerador/${arqx} &>/dev/null
        chmod +x ${DIR_BASE}/${arqx}
        
        # Distribución de archivos
        if [[ "$arqx" == "menu" ]]; then
            mv ${DIR_BASE}/${arqx} /usr/bin/menu
            chmod +x /usr/bin/menu
            chmod +x /usr/bin/adm
        elif [[ "$arqx" == "usercodes" ]]; then
             mv ${DIR_BASE}/${arqx} ${DIR_USER}/
        elif [[ "$arqx" == *.sh ]]; then
             mv ${DIR_BASE}/${arqx} ${DIR_INST}/
        else
             mv ${DIR_BASE}/${arqx} ${DIR_HERR}/
        fi
    done
}

# 5. Finalización
finalizar () {
    msg -bar
    msg -verd " INSTALACIÓN COMPLETADA "
    msg -ama " Escribe 'menu' para entrar"
    msg -bar
    rm -rf $0
}

# Ejecución
preparar_vps
crear_directorios
descargar_archivos
finalizar
