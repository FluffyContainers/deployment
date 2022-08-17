#!/bin/bash

# Copyright 2022 FluffyContainers
# GitHub: https://github.com/FluffyContainers

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# shellcheck disable=SC2155,SC2015

OS_TYPE=$(grep "^ID=" /etc/os-release | sed 's/ID=//')
OS_VERSION=$(grep "^VERSION_ID=" /etc/os-release | sed 's/VERSION_ID=//')

DIR=${PWD:-$(pwd)}

# =====================
# 
#  Terminal functions
#
# =====================
declare -A _COLOR=(
  [INFO]="\033[38;05;39m"
  [ERROR]="\033[38;05;161m"
  [WARN]="\033[38;05;178m"
  [OK]="\033[38;05;40m"
  [GRAY]="\033[38;05;245m"
  [RESET]="\033[m"
)


__command(){
  local title="$1"
  local status="$2"  # 0 or 1
  shift;shift

  [[ "${__DEBUG}" -eq 1 ]] && echo "${_COLOR[INFO]}[CMD-DBG] ${_COLOR[GRAY]} $* ${_COLOR[RESET]}"

  if [[ ${status} -eq 1 ]]; then
    echo -n "${title}..."
    "$@" 1>/dev/null 2>&1
    local n=$?
    [[ $n -eq 0 ]] && echo -e "${_COLOR[OK]}ok${_COLOR[RESET]}" || echo -e "${_COLOR[ERROR]}fail[#${n}]${_COLOR[RESET]}"
    return ${n}
  else
   echo "${title}..."
    "$@"
    return $?
  fi
}

__run(){
 echo -ne "${_COLOR[INFO]}[EXEC] ${_COLOR[GRAY]}$* -> ["
 "$@" 1>/dev/null 2>/dev/null
 local n=$?
 [[ $n -eq 0 ]] && echo -e "${_COLOR[OK]}ok${_COLOR[GRAY]}]${_COLOR[RESET]}" || echo -e "${_COLOR[ERROR]}fail[#${n}]${_COLOR[GRAY]}]${_COLOR[RESET]}"
 return ${n}
}

__echo() {
 local _lvl="INFO"
 [[ "${1^^}" == "INFO" ]] || [[ "${1^^}" == "ERROR" ]] || [[ "${1^^}" == "WARN" ]] && { local _lvl=${1^^}; shift; }
 
 echo -e "${_COLOR[${_lvl}]}[${_lvl}]${_COLOR[RESET]} $*"
}

__ask() {
    local _title="${1}"
    read -rep "${1} (y/N): " answer < /dev/tty
    if [[ "${answer}" != "y" ]]; then
      __echo "error" "Action cancelled by the user"
      return 1
    fi
    return 0
}



# ===========================================================================

check_podman_deployment(){
    podman -v 1>/dev/null 2>&1
    if [[ $? -ne 127 ]]; then
      local _podman_version=$(podman -v|awk '{print $3}')
      __echo "ERROR" "Podman instance version ${_podman_version} already deployed, aborting"
      return 1
    fi
    return 0
}

install_ubuntu(){
   read -rep "Please specify container network base address (i.e. 10.10.10): " podman_network < /dev/tty
   if [[ -z ${podman_network} ]] ; then
       __echo "error" "Action cancelled by the user"
      return 1
   fi

   __run apt install -y podman lxcfs

__info "Writting /etc/netplan/49-podman.yaml"
cat > /etc/netplan/49-podman.yaml <<EOF
network:
  version: 2
  renderer: networkd

  bridges:
    podman:
      addresses: [${podman_network}.1/24]
      mtu: 1500
EOF
  __run netplan generate 
  __run netplan --debug apply

__info "Writting /etc/cni/net.d/87-podman-bridge.conflist"
cat > /etc/cni/net.d/87-podman-bridge.conflist <<EOF
{
  "cniVersion": "0.4.0",
  "name": "podman",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "podman",
      "isGateway": true,
      "ipMasq": false,
      "hairpinMode": false,
      "ipam": {
        "type": "host-local",
        "routes": [{ "dst": "0.0.0.0/0" }],
        "ranges": [
          [
            {
              "subnet": "${podman_network}.0/24",
              "gateway": "${podman_network}.1"
            }
          ]
        ]
      }
    },
    {
      "type": "portmap",
      "capabilities": {
        "portMappings": true
      }
    },
    {
      "type": "firewall"
    },
    {
      "type": "tuning"
    }
  ]
}
EOF

__info "Writting /etc/containers/containers.conf"
cat > /etc/containers/containers.conf <<EOF
[containers]
cgroupns = "host"
cgroups = "enabled"
default_capabilities = [
    "AUDIT_WRITE",
    "CHOWN",
    "DAC_OVERRIDE",
    "FOWNER",
    "FSETID",
    "KILL",
    "MKNOD",
    "NET_BIND_SERVICE",
    "NET_RAW",
    "SETGID",
    "SETPCAP",
    "SETUID",
    "SYS_CHROOT",
]

ipcns = "private"
netns = "private"
pidns = "private"
utsns = "private"
#userns = "auto"

[network]
network_config_dir = "/etc/cni/net.d/"
network_backend = "cni"

[engine]
cgroup_manager = "cgroupfs"
events_logger = "journald"
runtime = "crun"

[engine.runtimes]
 runc = [
        "/usr/bin/crun"
 ]

 crun = [
            "/usr/bin/crun"
 ]

 kata = [
            "/usr/bin/crun",
 ]
EOF

   return 0
}


install() {
  __echo "Detected OS: ${OS_TYPE} ${OS_VERSION}"
  
  echo "Podman deployment script. "
  echo -en "You're about to deploy podman on current system "
  ! __ask "Agree to continue" && return 1
  ! check_podman_deployment && exit 1
  
  "install_${OS_TYPE}" 2>/dev/null

  if [[ $? -eq 127 ]]; then
    __echo "INFO" "Deployment for ${OS_TYPE} not implemented yet, stay tunned"
  fi
}


install