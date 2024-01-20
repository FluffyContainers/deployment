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
    [RED]="\033[38;05;160m"
    [DARKPINK]="\033[38;05;127m"
    [RESET]="\033[m"
)

# deprecated, should be overseeded by __run with porting functionality and letting it be simple as __run
__command(){
  local title="$1"
  [[ $2 -eq 1 ]] && local status="-s" || local status=""
    # 0 or 1
  shift;shift

  __run "${status}" -t "${title}" "$@"
}

# __run [-t "command caption" [-s] [-f "echo_func_name"]] [-a] [-o] [--stream] [--sudo] command
# -t       - instead of command itself, show the specified text
# -s       - if provided, command itself would be hidden from the output
# -f       - if provided, output of function would be displayed in title
# -a       - attach mode, command would be execute in curent context
# -o       - always show output of the command
# --stream - read application line-per-line and proxy output to stdout. In contrary to "-a", output are wrapped. 
# --sudo   - trying to exeute command under elevated permissions, when required. Forcing "-a" mode for sudo password input 
# Samples:
# _test(){
#  echo "lol" 
#}
# __run -s -t "Updating" -f "_test" update_dirs
__run(){
  local _default=1 _f="" _silent=0 _show_output=0 _custom_title="" _func="" _attach=0 _stream=0 _sudo=0

  # scan for arguments
  while true; do
    [[ "${1^^}" == "-S" ]]       && { _silent=1; shift; }
    [[ "${1^^}" == "-T" ]]       && { _custom_title="${2}"; shift; shift; _default=0; }
    [[ "${1^^}" == "-F" ]]       && { _func="${2}"; shift; shift; }
    [[ "${1^^}" == "-O" ]]       && { _show_output=1; shift; }
    [[ "${1^^}" == "-A" ]]       && { _attach=1; shift; }
    [[ "${1^^}" == "--STREAM" ]] && { _stream=1; shift; }
    [[ "${1^^}" == "--SUDO" ]]   && { _sudo=1; shift; } 

    [[ "${1:0:1}" != "-" ]] && break
  done

  [[ ${_sudo} -eq 1 ]] && { 
    [[ ${UID} -ne 0 ]] && { _stream=0; _attach=1; _show_output=0; set -- sudo "$@"; } || _sudo=0
  }

  [[ "${DEBUG}" == "1" ]] &&  echo -e "${_COLOR[GRAY]}[DEBUG] $*${_COLOR[RESET]}"

  [[ "${_custom_title}" != "" ]] && {
    echo -ne "${_custom_title} "
    [[ ${_silent} -eq 0 ]] && echo -ne "${_COLOR[GRAY]} | $*"
  }

  [[ ${_attach} -eq 1 ]] && {
    echo
    echo -e "${_COLOR[GRAY]}--------Attaching${_COLOR[RESET]}"
    "$@" 
    local n=$?
    echo -e "${_COLOR[GRAY]}----------Summary"
    echo -e "${_COLOR[DARKPINK]}[>>>>]${_COLOR[GRAY]} Exit code: ${n} ${_COLOR[RESET]}"
    return ${n}
  }
  
  [[ ${_silent} -eq 1 ]] ||  [[ ${_show_output} -eq 1 ]] || _stream=0;

  if [[ ${_stream} -eq 0 ]]; then
    local _out; _out=$("$@" 2>&1)
    local n=$?
  fi
  

  [[ -n ${_func} ]] && echo -ne " | $(${_f})"
  [[ ${_default} -eq 0 ]] || echo -ne "${_COLOR[INFO]}[EXEC] ${_COLOR[GRAY]}$*"
  
  [[ ${_stream} -eq 0 ]] && {
    [[ ${n} -eq 0 ]] && echo -e "${_COLOR[GRAY]} -> [${_COLOR[OK]}ok${_COLOR[GRAY]}]${_COLOR[RESET]}" || echo -e "${_COLOR[GRAY]} -> [${_COLOR[ERROR]}fail[#${n}]${_COLOR[GRAY]}]${_COLOR[RESET]}"
  } || echo

  [[ ${n} -ne 0 ]] && [[ ${_silent} -eq 0 ]] || [[ ${_show_output} -eq 1 ]] && {
    local _accent_color="DARKPINK"
    local _accent_symbol=">>>>"
    [[ ${n} -ne 0 ]] && { _accent_color="ERROR"; _accent_symbol="!!!!"; }

    if [[ ${_stream} -eq 0 ]]; then
      IFS=$'\n' mapfile -t out_lines <<< "${_out}"
      echo -e "${_COLOR[${_accent_color}]}[${_accent_symbol}]${_COLOR[GRAY]} ${out_lines[0]}"
      
      for line in "${out_lines[@]:1}"; do
          echo -e "${_COLOR[${_accent_color}]}     | ${_COLOR[GRAY]}${line}"
      done
    else
      echo -ne "${_COLOR[${_accent_color}]}[${_accent_symbol}]"
      local _first_line=0
      "$@" 2>&1 | while read -r line; do
        [[ ${_first_line} -eq 0 ]] && { echo -e " ${_COLOR[GRAY]}${line}"; _first_line=1; continue; }
        echo -e "${_COLOR[${_accent_color}]}     | ${_COLOR[GRAY]}${line}"
      done
      local n=${PIPESTATUS[0]}
      echo -ne "${_COLOR[${_accent_color}]}"
      echo -ne "[--->] "; [[ ${n} -eq 0 ]] && echo -e "${_COLOR[OK]}ok${_COLOR[RESET]}" || echo -e "${_COLOR[ERROR]}fail[#${n}]${_COLOR[RESET]}"
      
    fi
    echo -e "${_COLOR[RESET]}"
  }
  return "${n}"
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
    [[ -n ${FORCE} ]] && [[ "${FORCE}" == "1" ]] && echo "${1} (y/N): y (env variable)" || read -rep "${1} (y/N): " answer < /dev/tty
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
#        1 => >
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

_BIN_FILE="oh-my-posh"
_POSH_BIN_PATH="${HOME}/.local/bin"
_POSH_THEME="posh_theme.json"
_POSH_THEME_URL="${DEPL_CONFIG_URL}/posh/${_POSH_THEME}"
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

  __download -L "${_POSH_URL}" "${_POSH_BIN_PATH}/${_BIN_FILE}"
  __run chmod +x "${_POSH_BIN_PATH}/${_BIN_FILE}"
  __download -L "${_POSH_THEME_URL}" "${_CONFIG_DIR}/${_POSH_THEME}"
  __download -L "${_POSH_RC_URL}" "${_POSH_RC_PATH}"
  __run sed -i "s|::OMP::|${_POSH_BIN_PATH}/${_BIN_FILE}|g; s|::CONFIG::|${_CONFIG_DIR}/${_POSH_THEME}|g" "${_POSH_RC_PATH}" 
}

install_new(){
  upgrade

  cat >> "${_INSTALL_HOOK_TARGET}" <<EOF

# hook added by FluffyContainers deployment scripts
if [[ -f "${_POSH_RC_PATH}" ]]; then
  . ${_POSH_RC_PATH}
fi
EOF
}

install(){
  echo "Powerline deployment script. "
  echo -en "${_COLOR[ERROR]}You're about to deploy powerline on current system (user). ${_COLOR[RESET]}"
  ! __ask "Agree to continue" && return 1

  local _current_version="${_COLOR[ERROR]}not installed${_COLOR[RESET]}"

  if [[ -f "${_POSH_BIN_PATH}/${_BIN_FILE}" ]]; then
    _current_version=$("${_POSH_BIN_PATH}/${_BIN_FILE}" --version)
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