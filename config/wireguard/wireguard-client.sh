#!/bin/bash

add_client(){
 local _server_file=$2.conf
 local _private_key=$(cat ${_server_file}|grep PrivateKey|awk '{print $3}')
 local _server_pubkey=$(echo -n ${_private_key}|wg pubkey)
 local _name=$1
 local _inetif=$(ip route|grep default|awk '{print $5}')
 local _host_endpoint=$(ip -4 addr show dev ${_inetif} | grep inet |head -1|awk '{print $2}'|cut -d '/' -f 1)

 local _port=443
 local _client_pkey=$(wg genkey)
 local _client_pubkey=$(echo -n ${_client_pkey}|wg pubkey)

# client config

cat > [client]vpn-${_name}.conf <<EOF
[Interface]
PrivateKey = ${_client_pkey}
Address = 1.1.1.1/32

[Peer]
PublicKey = ${_server_pubkey}
AllowedIPs = 1.1.1.1/32
Endpoint = ${_host_endpoint}:${_port}
EOF

cat >> ${_server_file} <<EOF

; Client ${_name}
[Peer]
PublicKey = ${_client_pubkey}
AllowedIPs = 1.1.1.1/32
EOF
}

if [[ -z $1 ]] || [[ -z $2 ]]; then
 echo "wireguard-client.sh <client name> <server wg conf file name>"
 exit 1
fi

# $1 - server conf name
# $2 - client name
add_client "$2" "$1"