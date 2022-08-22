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

__download(){
  [[ "${1^^}" == "-L" ]] && { local _follow_link="-L"; shift; } || local _follow_link=""
  local _url="$1"
  local _file="${_url##*/}"
  [[ -z $2 ]] && local _destination="./" || local _destination="$2"

  __echo "Downloading file ${_file}: "
  curl -f "${_follow_link}" --progress-bar "${_url}" -o "${_destination}/${_file}" 2>&1
  local _ret=$?

  [[ ${_ret} -eq 0 ]] && {
    tput cuu1; echo -ne "\033[0K\r"; tput cuu1
    __echo "Downloading file ${_file}: [${_COLOR[OK]}OK${_COLOR[RESET]}]"
  } || {
    tput cuu1; echo -ne "\033[0K\r"; tput cuu1;echo -ne "\033[0K\r"; tput cuu1;
    __echo "Downloading file ${_file}: [${_COLOR[ERROR]}ERROR ${_ret}${_COLOR[RESET]}]"
  }
  return ${_ret}
}

__SSHD_DOWLOAD_URL="https://raw.githubusercontent.com/FluffyContainers/deployment/main/config/sshd"
__SSHD_CONFIG="sshd_config"
__SSHD_REPORT="login_report.sh"


install(){
  local OS_TYPE=$(grep "^ID=" /etc/os-release | sed 's/ID=//')

  local _platform="rhel"
  [[ "ubuntu debian" =~ (^|[[:space:]])"${OS_TYPE}"(|[[:space:]]) ]] &&  local _platform="ubuntu"

  # ===========================================
  local _sftp_path="/usr/libexec/openssh/sftp-server"
  if [[ ${PLATFORM} == "rhel" ]]; then 
    dnf install -y libpam-google-authenticator openssh-server
  else 
    apt update
    apt install -y libpam-google-authenticator
    local _sftp_path="/usr/lib/openssh/sftp-server"
  fi

  local _file="/etc/sshd/sshd_config"
  __run mv -f "${_file}" "${_file}.back"
  __download "${__SSHD_DOWLOAD_URL}/${__SSHD_CONFIG}" "${_file}"
  __run chown root:root "${_file}"
  __run chmod 600 "${_file}"

  local _listen="0.0.0.0"
  local _port="2222"
  local _2fa_group="gauth"
  local _ssh_group="ssh-users"

  sed -i "s/[LISTEN]/${_listen}/g;
          s/[PORT]/${_port}/g; 
          s/[SUBSYS]/${_sftp_path}/;
          s/[SSH-GROUP]/${_ssh_group}/g;
          s/[2FA-GROUP]/${_2fa_group}/g"
          "${_file}"


  local _file="/usr/local/bin/${__SSHD_REPORT}"
  __echo "Adding custom login alert script"
  __download "${__SSHD_DOWLOAD_URL}/${__SSHD_REPORT}" "${_file}"
  __run chown root:root "${_file}"
  __run chmod 540 "${_file}"

  local _chat_link=""
  local _server=""
  sed -i "s/[CHAT-LINK]/${_chat_link}/g;
          s/[SERVER]/${_server}/g;"
          "${_file}"

  echo -e "\n\nsession optional pam_exec.so seteuid /usr/local/bin/login_report.sh\n" >> /etc/pam.d/sshd

  __run sed -i 's|#%PAM-1.0|#%PAM-1.0\nauth required pam_google_authenticator.so nullok\n|' /etc/pam.d/sshd

}