#!/bin/bash


# Copyright 2024 FluffyContainers
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

# [start]
# options: optional

_PLATFORM_TYPE="amd64"; [[ ${HOSTTYPE} == "aarch64" ]] && _PLATFORM_TYPE="arm64"
_OS_TYPE=$(grep "^ID=" /etc/os-release | sed 's/ID=//;s/"//g')
_OS_VERSION=$(grep "^VERSION_ID=" /etc/os-release | sed 's/VERSION_ID=//;s/"//g')
read -ra _OS_LIKE <<< "$(grep "^ID_LIKE=" /etc/os-release | sed 's/ID_LIKE=//;s/"//g')"

# shellcheck disable=SC2120
info_header(){
    local __inject_rows_func="${1}"
    __echo "------"
    __echo "OS                    : ${_OS_TYPE} ${_OS_VERSION}"
    __echo "Platform              : ${_PLATFORM_TYPE}"
    __echo "Compatible            : ${_OS_LIKE[*]}"
    __echo "Application           : ${APP}"
    __echo "Base Install Dir      : ${HOME}"
    if [[ -n "${__inject_rows__func}" ]]; then
    __echo ""
     ${__inject_rows__func}
    fi
    __echo "------"
}

APP=""


__install(){
    echo "Install logic"
}

install_fedora(){
   # dnf install -y .....
   __install
}

install_debian(){
    #apt update
    #apt install -y .....
    __install
}


install(){
  info_header
  echo -en "You're about to deploy ${APP} on current system. "
  ! __ask "Agree to continue" && return 1
  
  if [[ $(type -t "install_${_OS_TYPE,,}") == function ]]; then
    "install_${_OS_TYPE,,}"
  else
    local _found=0
    for _compatible in "${_OS_LIKE[@]}"; do
      if [[ $(type -t "install_${_compatible,,}") == function ]]; then
         __echo "WARN" "\"${_OS_TYPE}\" is not directly supported, executing as compatible with \"${_compatible}\""
         sleep 2
         "install_${_compatible,,}"
         local _found=1
         break
      fi
    done 
    [[ ${_found} -eq 0 ]] && __echo "ERROR" "Unsupported OS Type"
  fi
}


# [end]