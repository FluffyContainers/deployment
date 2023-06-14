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


# [template] !!! DO NOT MODIFY CODE INSIDE. INSTEAD USE apply-teplate.sh script to update template !!!

# [module: core.sh]

# shellcheck disable=SC2155,SC2015

# =====================
#  Terminal functions
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
  local _new_line=""

  [[ "${1^^}" == "-N" ]] && { local _new_line="n"; shift; }
  [[ "${1^^}" == "INFO" ]] || [[ "${1^^}" == "ERROR" ]] || [[ "${1^^}" == "WARN" ]] && { local _lvl=${1^^}; shift; }
  
  echo -${_new_line}e "${_COLOR[${_lvl}]}[${_lvl}]${_COLOR[RESET]} $*"
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

cuu1(){
  echo -e "\E[A"
}

# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
# Results: 
#          0 => =
#          1 => >
#          2 => <
# shellcheck disable=SC2206
__vercomp () {
    [[ "$1" == "$2" ]] && return 0 ; local IFS=. ; local i ver1=($1) ver2=($2)
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++));  do ver1[i]=0;  done
    for ((i=0; i<${#ver1[@]}; i++)); do
        [[ -z ${ver2[i]} ]] && ver2[i]=0
        ((10#${ver1[i]} > 10#${ver2[i]})) &&  return 1
        ((10#${ver1[i]} < 10#${ver2[i]})) &&  return 2
    done
    return 0
}

__urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

__download() {
  [[ "${1^^}" == "-L" ]] && { local _follow_link="-L"; shift; } || local _follow_link=""
  local _url="$1"
  local _file=$(__urldecode "${_url##*/}")
  [[ -z $2 ]] && local _destination="./" || local _destination="$2"
  [[ "${_destination:0-1}" == "/" ]] && local _dest_path="${_destination}/${_file}" || local _dest_path="${_destination}"

  __echo "Downloading file ${_file}: "
  # shellcheck disable=SC2086
  curl -f ${_follow_link} --progress-bar "${_url}" -o "${_dest_path}" 2>&1
  local _ret=$?

  [[ ${_ret} -eq 0 ]] && {
    echo -ne "\E[A"; echo -ne "\033[0K\r"; echo -ne "\E[A"
    __echo "Downloading file ${_file}: [${_COLOR[OK]}ok${_COLOR[RESET]}]"
  } || {
    echo -ne "\E[A"; echo -ne "\033[0K\r"; echo -ne "\E[A";echo -ne "\033[0K\r"; echo -ne "\E[A";
    __echo "Downloading file ${_file}: [${_COLOR[ERROR]}fail ${_ret}${_COLOR[RESET]}]"
  }
  return ${_ret} 
}


# [module: hardcode.sh]
DEPL_BRANCH="main"
DEPL_MAIN_DOWNLOAD_URL="https://raw.githubusercontent.com/FluffyContainers/deployment/${DEPL_BRANCH}"
DEPL_CONFIG_URL="${DEPL_MAIN_DOWNLOAD_URL}/config"

# [template] [end] !!! DO NOT REMOVE ANYTHING INSIDE, INCLUDING CURRENT LINE !!!

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
   
   # on rhel - dnf install containernetworking-plugins

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
      "bridge": "br-podman",
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
              "gateway": "${podman_network}.1",
              "rangeStart": "${podman_network}.2",
              "rangeEnd": "${podman_network}.254"
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

local _storage="/mnt/data/podman"

__info "Writting /etc/containers/storage.conf"
mkdir -p "${_storage}"
cat > /etc/containers/storage.conf <<EOF
[storage]
driver = "overlay"

runroot = "/run/containers/storage"
graphroot = "${_storage}"

[storage.options]
additionalimagestores = [
]


[storage.options.overlay]
#ignore_chown_errors = "false"
# inodes = ""
#mount_program = "/usr/bin/fuse-overlayfs"

mountopt = "nodev,metacopy=on"

# skip_mount_home = "false"
# size = ""

#  "": No value specified.
#  "private": it is equivalent to 0700.
#  "shared": it is equivalent to 0755.
# force_mask = ""
EOF

   return 0
}


install() {
  __echo "Detected OS: ${OS_TYPE} ${OS_VERSION}"
  
  echo "Podman deployment script. "
  echo -en "You're about to deploy podman on current system. "
  ! __ask "Agree to continue" && return 1
  ! check_podman_deployment && exit 1
  
  "install_${OS_TYPE}" 2>/dev/null

  if [[ $? -eq 127 ]]; then
    __echo "INFO" "Deployment for ${OS_TYPE} not implemented yet, stay tunned"
  fi
}


install