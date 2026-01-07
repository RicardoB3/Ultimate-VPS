#!/bin/bash
# Script Instalador Ultimate-VPS (Versión Restaurada y Corregida)
# Compatible: Ubuntu 20.04 / 22.04 LTS
# Adaptado para el repositorio: RicardoB3

# --- CONFIGURACIÓN DEL REPOSITORIO ---
USUARIO="RicardoB3"
REPO="Ultimate-VPS"
RAMA="master"
# -------------------------------------

URL_RAW="https://raw.githubusercontent.com/${USUARIO}/${REPO}/${RAMA}"
DIR_BASE="/etc/newadm"
DIR_USER="${DIR_BASE}/ger-user"
DIR_INST="/etc/ger-inst"
DIR_HERR="/etc/ger-frm"

# --- COLORES Y ESTÉTICA ---
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

# --- VERIFICACIÓN INICIAL ---
[[ $EUID -ne 0 ]] && msg -verm "Error: Este script necesita permisos root (sudo)." && exit 1

# --- 1. PREPARACIÓN DEL SISTEMA ---
preparar_vps () {
    clear
    msg -bar
    msg -ama "PREPARANDO SISTEMA (UBUNTU 20/22)..."
    
    # Eliminar bloqueos de apt
    rm -rf /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
    
    # Actualizar repositorios
    msg -azu "Actualizando lista de paquetes..."
    apt-get update -y > /dev/null 2>&1
    
    # Instalación de paquetes esenciales
    # 'python-is-python3' es vital para que tus scripts antiguos funcionen en Ubuntu 22
    PAQUETES="jq bc screen curl ufw unzip zip net-tools nano python3 python3-pip python-is-python3 cron apache2 at"
    
    msg -azu "Instalando dependencias y herramientas..."
    for paq in $PAQUETES; do
        [[ $(dpkg --get-selections|grep -w "$paq"|head -1) ]] || apt-get install $paq -y &>/dev/null
        echo -ne "\033[1;32m [OK] $paq \033[0m"
    done
    echo ""

    # Configuración de Apache (Puerto 81)
    if [[ -f /etc/apache2/ports.conf ]]; then
        sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf
        service apache2 restart > /dev/null 2>&1
    fi
}

# --- 2. GENERADOR DE TRADUCTOR (TITAN FIX) ---
# Creamos el archivo /usr/bin/trans localmente para evitar errores de dependencias
crear_traductor () {
    msg -azu "Generando herramienta de traducción..."
    cat << 'EOF' > /usr/bin/trans
#!/usr/bin/env python3
import urllib.request
import urllib.parse
import json
import sys

# Script de traducción optimizado sin dependencias externas (requests)
def traducir(text, source="auto", target="es"):
    url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=" + source + "&tl=" + target + "&dt=t&q=" + urllib.parse.quote(text)
    headers = {"User-Agent": "Mozilla/5.0"}
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            if data and len(data) > 0 and data[0]:
                print("".join([x[0] for x in data[0] if x]))
            else:
                print(text)
    except:
        print(text)

if __name__ == '__main__':
    # Argumentos simples: trans "texto a traducir"
    if len(sys.argv) > 1:
        texto = " ".join(sys.argv[1:])
        traducir(texto)
    else:
        print("Error: Falta texto")
EOF
    chmod +x /usr/bin/trans
}

# --- 3. GESTIÓN DE DIRECTORIOS ---
crear_directorios () {
    mkdir -p ${DIR_BASE}
    mkdir -p ${DIR_USER}
    mkdir -p ${DIR_INST}
    mkdir -p ${DIR_HERR}
}

# --- 4. DESCARGA DEL REPOSITORIO ---
descargar_archivos () {
    msg -bar
    msg -ama "DESCARGANDO SCRIPTS DESDE GITHUB..."
    
    # Descargar la lista GERADOR desde la carpeta 'gerador' de tu GitHub
    wget -O ${DIR_BASE}/lista-arq ${URL_RAW}/gerador/GERADOR &>/dev/null
    
    if [[ ! -s ${DIR_BASE}/lista-arq ]]; then
        msg -verm "ERROR FATAL: No se encontró 'gerador/GERADOR' en tu GitHub."
        msg -verm "Verifica la URL: ${URL_RAW}/gerador/GERADOR"
        exit 1
    fi

    # Leer lista y descargar cada archivo
    for arqx in $(cat ${DIR_BASE}/lista-arq); do
        msg -azu "Descargando: $arqx"
        
        # Descarga el archivo desde la carpeta 'gerador'
        wget -O ${DIR_BASE}/${arqx} ${URL_RAW}/gerador/${arqx} &>/dev/null
        chmod +x ${DIR_BASE}/${arqx}
        
        # Clasificación y movimiento de archivos
        if [[ "$arqx" == "menu" ]]; then
            mv ${DIR_BASE}/${arqx} /usr/bin/menu
            chmod +x /usr/bin/menu
            # Crear alias 'adm' también
            cp /usr/bin/menu /usr/bin/adm
        elif [[ "$arqx" == "usercodes" ]]; then
             mv ${DIR_BASE}/${arqx} ${DIR_USER}/
        elif [[ "$arqx" == *.sh ]]; then
             mv ${DIR_BASE}/${arqx} ${DIR_INST}/
        else
             mv ${DIR_BASE}/${arqx} ${DIR_HERR}/
        fi
    done
}

# --- 5. FINALIZACIÓN ---
finalizar () {
    msg -bar
    msg -verd " INSTALACIÓN COMPLETADA CON ÉXITO "
    msg -ama " Soporte: Ubuntu 20.04 / 22.04 LTS"
    msg -ama " Para iniciar escribe: menu"
    msg -bar
    # Borrar el instalador
    rm -f $0
}

# --- EJECUCIÓN DEL FLUJO ---
preparar_vps
crear_traductor
crear_directorios
descargar_archivos
finalizar
