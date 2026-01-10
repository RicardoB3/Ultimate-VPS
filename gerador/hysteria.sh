#!/bin/bash
HYSTERIA_DIR="/etc/hysteria"
HYSTERIA_BIN="/usr/local/bin/hysteria"
HYSTERIA_CONF="${HYSTERIA_DIR}/config.yaml"
HYSTERIA_CERT="${HYSTERIA_DIR}/server.crt"
HYSTERIA_KEY="${HYSTERIA_DIR}/server.key"
HYSTERIA_SERVICE="/etc/systemd/system/hysteria-server.service"

install_hysteria() {
    msg -ama "$(fun_trans "Instalando Hysteria UDP v1")"
    msg -bar

    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64) hysteria_arch="amd64";;
        aarch64|arm64) hysteria_arch="arm64";;
        armv7l|armv7) hysteria_arch="arm";;
        *)
            msg -ama "$(fun_trans "Arquitetura nao suportada")"
            return 1
            ;;
    esac

    mkdir -p "${HYSTERIA_DIR}"
    if [[ ! -x "${HYSTERIA_BIN}" ]]; then
        version="v1.3.5"
        url="https://github.com/HyNetwork/hysteria/releases/download/${version}/hysteria-linux-${hysteria_arch}"
        msg -ama "$(fun_trans "Baixando Hysteria")"
        msg -bar
        if ! curl -fsSL -o "${HYSTERIA_BIN}" "${url}"; then
            msg -ama "$(fun_trans "Falha ao baixar Hysteria")"
            return 1
        fi
        chmod +x "${HYSTERIA_BIN}"
    fi

    if [[ ! -f "${HYSTERIA_CERT}" || ! -f "${HYSTERIA_KEY}" ]]; then
        msg -ama "$(fun_trans "Gerando certificado SSL")"
        msg -bar
        openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
            -subj "/CN=Hysteria" -keyout "${HYSTERIA_KEY}" -out "${HYSTERIA_CERT}" >/dev/null 2>&1
    fi

    local hysteria_port
    local hysteria_pass
    msg -ama "$(fun_trans "Escolha a porta UDP para Hysteria")"
    read -p " [36712]: " hysteria_port
    hysteria_port=${hysteria_port:-36712}

    msg -ama "$(fun_trans "Defina uma senha para Hysteria")"
    read -p " $(fun_trans "Senha"): " hysteria_pass

    cat > "${HYSTERIA_CONF}" <<CONFIG
listen: :${hysteria_port}
cert: ${HYSTERIA_CERT}
key: ${HYSTERIA_KEY}
auth: ${hysteria_pass}
alpn: h3
CONFIG

    cat > "${HYSTERIA_SERVICE}" <<SERVICE
[Unit]
Description=Hysteria UDP Server
After=network.target

[Service]
Type=simple
ExecStart=${HYSTERIA_BIN} server -c ${HYSTERIA_CONF}
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
SERVICE

    systemctl daemon-reload
    systemctl enable --now hysteria-server >/dev/null 2>&1
    msg -bar
    msg -ama "$(fun_trans "Hysteria iniciado com sucesso")"
}

remove_hysteria() {
    msg -ama "$(fun_trans "Parando Hysteria")"
    msg -bar
    systemctl disable --now hysteria-server >/dev/null 2>&1
    rm -f "${HYSTERIA_SERVICE}"
    systemctl daemon-reload
    msg -ama "$(fun_trans "Hysteria removido")"
}

if [[ -f "${HYSTERIA_SERVICE}" || -x "${HYSTERIA_BIN}" ]]; then
    msg -ama "$(fun_trans "Hysteria ja instalado. Deseja remover")?"
    msg -bar
    while [[ ${resp} != @(s|S|n|N|y|Y) ]]; do
        read -p " [S/N]: " -e -i n resp
        tput cuu1 && tput dl1
    done
    if [[ ${resp} = @(s|S|y|Y) ]]; then
        remove_hysteria
    fi
else
    install_hysteria
fi
