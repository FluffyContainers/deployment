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

# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
# Results: 
#          0 => =
#          1 => >
#          2 => <
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

# ===========================================================================

_BIN_FILE="oh-my-posh"
_POSH_BIN_PATH="${HOME}/.local/bin"
_POSH_THEME="posh_theme.json"
_POSH_THEME_URL="https://raw.githubusercontent.com/FluffyContainers/deployment/main/config/${_POSH_THEME}"
_CONFIG_DIR="${HOME}/.config/posh"
_POSH_RELEASE_URL="https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases/latest"
_POSH_RC_URL="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/src/shell/scripts/omp.bash"
_POSH_RC_PATH="${HOME}/.omprc"
_POSH_LATEST_VERSION=$(curl ${_POSH_RELEASE_URL} 2>/dev/null|grep "tag_name"|cut -d ":" -f 2|cut -d \" -f 2)
_PLATFORM_TYPE="amd64"; [[ ${HOSTTYPE} == "aarch64" ]] && _PLATFORM_TYPE="arm64"
_POSH_URL="https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/${_POSH_LATEST_VERSION}/posh-linux-${_PLATFORM_TYPE}"
_INSTALL_HOOK_TARGET="${HOME}/.bashrc"




info_header(){
    __echo "------"
    __echo "Current POSH Version  : $1"
    __echo "Available POSH Version: ${_POSH_LATEST_VERSION:1}"
    __echo "Platform              : ${_PLATFORM_TYPE}"
    __echo ""
    __echo "Download link         : ${_POSH_URL}"
    __echo "Base Install Dir      : ${HOME}"
    __echo "------"
}

upgrade(){
  local _dirs=(
    "${_POSH_BIN_PATH}"
    "${_CONFIG_DIR}"
  )
  for d in "${_dirs[@]}"; do
    [[ ! -d "${d}" ]] && __run mkdir -p "${d}"
  done

  __run curl -L "${_POSH_URL}" -o "${_POSH_BIN_PATH}/${_BIN_FILE}"
  __run curl -L "${_POSH_THEME_URL}" -o "${_CONFIG_DIR}/${_POSH_THEME}"
  __run curl -L ${_POSH_RC_URL} -o "${_POSH_RC_PATH}"
  __run sed -i "s|::OMP::|${_POSH_BIN_PATH}/${_BIN_FILE}|g; s|::CONFIG::|${_CONFIG_DIR}/${_POSH_THEME}|g" "${_POSH_RC_PATH}"

  
}

install_new(){
  upgrade

  cat >> "${_INSTALL_HOOK_TARGET}" <<EOF
# hook added by FluffyContainers deployment scripts
 [[ -f "${_POSH_RC_PATH}"]] && . ${_POSH_RC_PATH} || true
EOF
}

install(){
  echo "Powerline deployment script. "
  echo -en "${_COLOR[ERROR]}You're about to deploy powerline on current system (user). ${_COLOR[RESET]}"
  ! __ask "Agree to continue" && return 1

 local _current_version="${_COLOR[ERROR]}not installed${_COLOR[RESET]}"

 if [[ -f "${_POSH_BIN_PATH}/${_BIN_FILE}" ]]; then
   _current_version=$("${_POSH_BIN_PATH}/${_BIN_FILE}" -version)
   __vercomp "${_POSH_LATEST_VERSION:1}" "${_current_version}"
   if [[ "0 1" =~ (^|[[:space:]])$?($|[[:space:]]) ]]; then
     info_header "${_current_version}"
     __echo "Local powerline version \"${_COLOR[WARN]}${_current_version}${_COLOR[RESET]}\" is older than available \"${_COLOR[OK]}${_POSH_LATEST_VERSION:1}${_COLOR[RESET]}\""
     ! __ask "Upgrade local version to most recent one? " && return 1
     
     upgrade
   fi
 else 
  info_header "${_current_version}"
   ! __ask "Pursuit with installation? " && return 1
  install_new
 fi

 __echo "Installation complete, reload console or execute: source \"${_POSH_RC_PATH}\""
}

install
