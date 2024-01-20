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

# __run [-t "command caption" [-s] [-f "echo_func_name"]] [-a] [-o] command
# -t       - instead of command itself, show the specified text
# -s       - if provided, command itself would be hidden from the output
# -f       - if provided, output of function would be displayed in title
# -a       - attach mode, command would be execute in curent context
# -o       - always show output of the command
# --stream - read application line-per-line and proxy output to stdout. In contrary to "-a", output are wrapped. 
# Samples:
# _test(){
#  echo "lol" 
#}
# __run -s -t "Updating" -f "_test" update_dirs
# TODO: make it more compact somehow
__run(){
  local _default=1 _f="" _silent=0 _show_output=0 _custom_title="" _func="" _attach=0 _stream=0

  # scan for arguments
  while true; do
    [[ "${1^^}" == "-S" ]]       && { _silent=1; shift; }
    [[ "${1^^}" == "-T" ]]       && { _custom_title="${2}"; shift; shift; _default=0; }
    [[ "${1^^}" == "-F" ]]       && { _func="${2}"; shift; shift; }
    [[ "${1^^}" == "-O" ]]       && { _show_output=1; shift; }
    [[ "${1^^}" == "-A" ]]       && { _attach=1; shift; }
    [[ "${1^^}" == "--STREAM" ]] && { _stream=1; shift; }

    [[ "${1:0:1}" != "-" ]] && break
  done

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


_PLATFORM_TYPE="amd64"; [[ ${HOSTTYPE} == "aarch64" ]] && _PLATFORM_TYPE="arm64"
_OS_TYPE=$(grep "^ID=" /etc/os-release | sed 's/ID=//;s/"//g')
_OS_VERSION=$(grep "^VERSION_ID=" /etc/os-release | sed 's/VERSION_ID=//;s/"//g')
read -ra _OS_LIKE <<< "$(grep "^ID_LIKE=" /etc/os-release | sed 's/ID_LIKE=//;s/"//g')"

APP="neovim"

declare -A _ALIASES=(
    [VIM]="nvim"
    [VI]="nvim"
)

DOWNLOAD_FILES=(
    "init.lua"
    "plugins.lua"
    "chadrc.lua"
    "configs/lspconfig.lua"
)

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

__adhock(){
  for key in "${!_ALIASES[@]}"; do
   local value="$(alias "${key,,}" 2>/dev/null|cut -d '=' -f 2)" 
   if ! alias "${key,,}" 1>/dev/null 2>&1; then
     __echo "[.bashrc change]       : setting alias ${key} to to ${_ALIASES[${key}]}"
   elif [[ "${value}" != "${_ALIASES[${key}]}" ]]; then
     __echo "[.bashrc change]       : setting alias ${key} from value \"${value}\" to \"${_ALIASES[${key}]}\""
   fi
  done
}


__help(){
cat<<EOF
================
     HELP
================
After first load of nvim please answer the question as below: 
  => do you want to install example custom config (y/n)? n

Basic commands:                  =====shell windows
===============                  in split => space + h, space + v
Cheatsheet => space + c h        floating => A-i
Quickhelp - press space and wait
Select theme =>  space + t h

=========FileTree                 ===== Search
File tree -> c + n                Open file -> space + f f
focus tree -> space + e           Open from buffer -> space + f b
Mark file - m
Create file - a                   ===== Splits
Copy file - c                     Vertical -> :vsp
Paste file - p                    Horizontal -> :sp
Rename - r                        Navigation => C-h C-j C-k C-l

=========Editor
Toggle line numbers -> Space + n
Toggle relative line numer -> space + r n
Navigate tabs:  tab, shift + tab

EOF
__echo "warn" "Reload shell to apply .bashrc changes or execute "source ~/.bashrc""
}

# Language server configs:
#  https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
#  settings in: configs/lspconfig.ua
__install(){
   __run rm -rf ~/.local/share/nvim
   __run rm -rf "${HOME}/.config/nvim"
   __run git clone https://github.com/NvChad/NvChad "${HOME}/.config/nvim" --depth 1
   __run mkdir -p ~/.config/nvim/lua/custom/configs

   for file in "${DOWNLOAD_FILES[@]}"; do
     __download -L "${DEPL_CONFIG_URL}/${APP}/${file}" "${HOME}/.config/nvim/lua/custom/${file}"
   done

  for key in "${!_ALIASES[@]}"; do
   local value="$(alias "${key,,}" 2>/dev/null|cut -d '=' -f 2)" 
   if ! alias "${key,,}" 1>/dev/null 2>&1 || [[ "${value}" != "${_ALIASES[${key}]}" ]]; then
     __echo "[.bashrc change] Adding alias \"${key,,}\" with  value ${_ALIASES[${key}]}"
     echo "alias ${key,,}='${_ALIASES[${key}]}'" >> "${HOME}/.bashrc"
   fi
  done

   __help
}

install_neovim_bin(){
  __download -L https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz /opt/nvim-linux64.tar.gz
  __run tar xf /opt/nvim-linux64.tar.gz -C /usr/local --strip-components=1
  __run rm -f /opt/nvim-linux64.tar.gz
}

install_fedora(){
   __run -o --stream dnf install -y gcc git npm
   if ! __run dnf install -y neovim; then
     __echo "WARN" "Neovim is not in the repos, installing standalone binary instead..."
     install_neovim_bin
   fi 
   __install
}


install_ubuntu(){
  __run apt update
  __run -o --stream apt install -y gcc git npm curl
  # Ubuntu installs too old version of neovim, opting to manual install https://github.com/neovim/neovim/blob/master/INSTALL.md
  install_neovim_bin
  __install
}

install_debian(){
    install_ubuntu
}

install_alpine(){
    __run apk update
    __run apk add gcc git npm curl neovim musl-dev
    __install
}


install(){
  info_header __adhock
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

install