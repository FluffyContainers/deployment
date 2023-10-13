#!/bin/bash

# =========== GENERATE WG CONFIGS

gen_wg_config(){
        local _name=$1
        local _ip_mask=$2
        local _net=$3
        local _port=443
        local _server_pkey=$(wg genkey)
        local _server_pubkey=$(echo -n ${_server_pkey}|wg pubkey)

        local _client_pkey=$(wg genkey)
        local _client_pubkey=$(echo -n ${_client_pkey}|wg pubkey)

 # server config
cat > [server]vpn-${_name}.conf <<EOF
[Interface]
PrivateKey = ${_server_pkey}
Address = ${_ip_mask}.1/${_net}
ListenPort = ${_port}
SaveConfig = true

[Peer]
PublicKey = ${_client_pubkey}
AllowedIPs = ${_ip_mask}.0/${_net}
EOF

# client config
local _inetif=$(ip route|grep default|awk '{print $5}')
local _host_endpoint=$(ip -4 addr show dev ${_inetif} | grep inet |head -1|awk '{print $2}'|cut -d '/' -f 1)

cat > [client]vpn-${_name}.conf <<EOF
[Interface]
PrivateKey = ${_client_pkey}
Address = ${_ip_mask}.2/${_net}

[Peer]
PublicKey = ${_server_pubkey}
AllowedIPs = ${_ip_mask}.0/${_net}
Endpoint = ${_host_endpoint}:${_port}
EOF
}

gen_wg_config "vpn-darkDE" "10.255.1.248" "29"
