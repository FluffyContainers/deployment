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

# shellcheck disable=SC2155,SC2015,SC2002

_LISTEN="0.0.0.0"
_PORT="2222"
_2FA_GROUP="gauth"
_SSH_GROUP="ssh-users"

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
    [[ -n ${FORCE} ]] && [[ "${FORCE}" == "1" ]] && { echo "${1} (y/N): y (env variable)"; return 0; } || read -rep "${1} (y/N): " answer < /dev/tty
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

# ===================== BASH MENU

moveCursor() {
    echo -ne "\033[$(($2+1));$1f"  # or tput cup "$2" "$1"
}


getCurrentPos(){
    local _col; local _row
    # shellcheck disable=SC2162
    IFS=';' read -sdR -p $'\E[6n' _row _col
    echo "${_col} ${_row#*[}"
}

readKey(){
    read -rsN 1 _key
    printf %d "'${_key}"   # %x for hex
}

redrawMenuItems() { 
    local -n _menuItems=$1
    local startPos=$2; local pos=$3; local oldPos=$4
    local menuLen=$((${#_menuItems[@]} + 2))
    local menuOldPosY=$((startPos - (menuLen - oldPos)))
    local menuNewPosY=$((startPos - (menuLen - pos)))
    
    moveCursor "0" "${menuOldPosY}"
    echo -ne "\t${_COLOR[UNSELECTED]}${oldPos}. ${_menuItems[${oldPos}]}${_COLOR[RESET]}" 

    moveCursor "0" "${menuNewPosY}"
    echo -ne "\t${_COLOR[SELECTED]}${pos}. ${_menuItems[${pos}]}${_COLOR[RESET]}"

    moveCursor "0" "${startPos}"
}

drawMenu() {
    local -n _menuItems=$1
    local menuPosition=$2
    local menuTitle="$3"

    local __line=$(printf '%*s' "${#menuTitle}" | tr ' ' "=")
    echo -ne "
\t${_COLOR[UNSELECTED]}${__line}${_COLOR[RESET]}
\t${_COLOR[UNSELECTED]} $menuTitle ${_COLOR[RESET]}
\t${_COLOR[UNSELECTED]}${__line}${_COLOR[RESET]}
    "
    echo
    for i in $(seq 0 ${#_menuItems[@]}); do
        [[ $i -ne ${menuPosition} ]] && local __color="UNSELECTED" || local __color="SELECTED"
        [[ -n "${_menuItems[${i}]}" ]] &&  echo -e "\t${_COLOR[${__color}]}$i. ${_menuItems[${i}]}${_COLOR[RESET]}" 
    done
    echo 
}


menu(){
    IFS="," read -ra menuItems <<< "$1"
    local menuTitle="$2"

    local keyCode=(0)
    local pos=0
    local oldPos=0

    drawMenu "menuItems" "${pos}" "${menuTitle}"

    local startPosStr=$(getCurrentPos);
    local startPos="${startPosStr#* }"

    while [[ ${keyCode[0]} -ne 10 ]]; do
        local keyCode=("$(readKey)") # byte 1
        if [[ ${keyCode[0]} -eq 27 ]]; then # escape character 
            local keyCode+=("$(readKey)") # byte 2
            if [[ ${keyCode[-1]} -ne 27 ]]; then # checking if user pressed actual
                local keyCode+=("$(readKey)")  # byte 3
                
                if [[ "51 50 48 52 53 54" =~ (^|[[:space:]])"${keyCode[2]}"($|[[:space:]]) ]]; then
                    while [[ ${keyCode[-1]} -ne 126 ]]; do
                        local keyCode+=("$(readKey)")    
                    done
                fi
                if [[ "49" =~ (^|[[:space:]])"${keyCode[2]}"($|[[:space:]]) ]]; then
                    local keyCode+=("$(readKey)")  # byte 4
                    [[ ${keyCode[-1]} -ne 126 ]] && local keyCode+=("$(readKey)") # byte 5
                    [[ ${keyCode[-1]} -eq 59 ]] && local keyCode+=("$(readKey)") # byte 5 check
                    [[ ${keyCode[-1]} -ne 126 ]] && local keyCode+=("$(readKey)")
                fi
            fi
        fi 

        local oldPos=${pos}
        case "${keyCode[*]}" in 
            "27 91 65")  local pos=$((pos - 1));;  # up
            "27 91 66")  local pos=$((pos + 1));;  # down
            "27 91 53 126") local pos=$((pos - 2));; # pgup
            "27 91 54 126") local pos=$((pos + 2));; # pgdn
            "27 91 72") local pos=0;; # home
            "27 91 70") local pos=$((${#menuItems[*]} - 1));; # end
            "27 27") return 255; # 2 presses of ESC
        esac

        [[ ${pos} -lt 0 ]] && local pos=0
        [[ ${pos} -ge ${#menuItems[*]} ]] && local pos=$((${#menuItems[*]} - 1))

        redrawMenuItems "menuItems" "${startPos}" "${pos}" "${oldPos}"  

    done

    return "${pos}"
}
# =====================

__SSHD_DOWLOAD_URL="${DEPL_CONFIG_URL}/sshd"
__SSHD_CONFIG="sshd_config"
__SSHD_REPORT="login_report.sh"


# user_wizzard(){
  
# }

install(){
  local OS_TYPE=$(grep "^ID=" /etc/os-release | sed 's/ID=//')
  local _platform="rhel"
  [[ "ubuntu debian" =~ (^|[[:space:]])"${OS_TYPE}"(|[[:space:]]) ]] &&  local _platform="ubuntu"

  # ===========================================
  local _sftp_path="/usr/libexec/openssh/sftp-server"
  if [[ ${_platform} == "rhel" ]]; then 
    dnf install -y google-authenticator openssh-server
  else 
    apt update
    apt install -y libpam-google-authenticator
    local _sftp_path="/usr/lib/openssh/sftp-server"
  fi

  local _file="/etc/ssh/sshd_config"
  __run mv -f "${_file}" "${_file}.back"
  __download "${__SSHD_DOWLOAD_URL}/${__SSHD_CONFIG}" "${_file}"
  __run chown root:root "${_file}"
  __run chmod 600 "${_file}"

  __run sed -i "s|\[LISTEN\]|${_LISTEN}|g;
          s|\[PORT\]|${_PORT}|g; 
          s|\[SUBSYS\]|${_sftp_path}|;
          s|\[2FA-GROUP\]|${_2FA_GROUP}|g;
          s|\[SSH\-GROUP\]|${_SSH_GROUP}|g" "${_file}"

  __run groupadd --system --force "${_2FA_GROUP}"
  __run groupadd --system --force "${_SSH_GROUP}"
  grep "pam_google_authenticator.so" /etc/pam.d/sshd 1>/dev/null 2>&1 && __echo "sshd 2fa hook already exist, skipping" || {
    if [[ "${_platform}" == "rhel" ]]; then
      __run sed -i 's|#%PAM-1.0|#%PAM-1.0\nauth required pam_google_authenticator.so nullok\n|' /etc/pam.d/sshd
    else
      __run sed -i 's|# PAM configuration for the Secure Shell service|# PAM configuration for the Secure Shell service\n\nauth required pam_google_authenticator.so nullok\n|' /etc/pam.d/sshd
    fi
  }
}

install_login_alert(){
  local _file="/usr/local/bin/${__SSHD_REPORT}"

  [[ ! -f /etc/pam.d/sshd ]] && { __echo "ERROR" "No sshd pam.d file found"; return 1; }
  [[ -f "${_file}" ]] && { __echo "ERROR" "Already present"; return 1; }
  if grep "${__SSHD_REPORT}" /etc/pam.d/sshd; then
    __echo "ERROR" "Hook already present"
    return 1
  fi

  __echo "Adding custom login alert script"
  __download "${__SSHD_DOWLOAD_URL}/${__SSHD_REPORT}" "${_file}"
  __run chown root:root "${_file}"
  __run chmod 540 "${_file}"

  local _chat_link=""
  local _server="${HOSTNAME}"

  __echo "---------------------------------------------------------------------------------"
  __echo "How to get hook link: "
  __echo " - go to the chat.google.com"
  __echo " - create new/select existing space"
  __echo " - space name -> manage webhooks -> (set a new hook name) -> copy hook link "
  __echo "---------------------------------------------------------------------------------"

  read -rp "Chat link: " _chat_link
  local _chat_link=${_chat_link//\&/\\\&}
  __run sed -i "s|\[CHAT\-LINK\]|${_chat_link}|g;
          s|\[SERVER\]|${_server}|g;" "${_file}"


  grep "${_file}" /etc/pam.d/sshd 1>/dev/null 2>&1 && { __echo "WARN" "Alert pam.d already present"; } || {
    echo -e "\n\nsession optional pam_exec.so seteuid /usr/local/bin/login_report.sh\n" >> /etc/pam.d/sshd 
    __echo "Alert hook added to the pam.d" 
  }
  
}

configure_sshguard(){
  echo "not here yet"
}

configure_user(){
  local OS_TYPE=$(grep "^ID=" /etc/os-release | sed 's/ID=//')
  local _platform="rhel"
  [[ "ubuntu debian" =~ (^|[[:space:]])"${OS_TYPE}"(|[[:space:]]) ]] &&  local _platform="ubuntu"

  read -rep "User name to create or modify: " username
  
  if ! cat "/etc/passwd" | awk -F ':' '{print $1}'| grep "${username}" 1>/dev/null 2>&1; then
    __echo "Creaing new user \"${username}\""
    if [[ "${_platform}" == "rhel" ]]; then
      __run adduser --shell /bin/bash "${username}"
    else
      __run adduser --shell /bin/bash --gecos "" "${username}"
    fi
    passwd "${username}"
  fi

  if ! groups "${username}" | awk -F ':' '{print $2}' | grep "${_SSH_GROUP}" 1>/dev/null 2>/dev/null; then 
    __echo "Adding user \"${username}\" to the group \"${_SSH_GROUP}\""
    __run usermod -a -G "${_SSH_GROUP}" "${username}"
  fi
  
}

configure_2fa(){
  local OS_TYPE=$(grep "^ID=" /etc/os-release | sed 's/ID=//')
  local _platform="rhel"
  [[ "ubuntu debian" =~ (^|[[:space:]])"${OS_TYPE}"(|[[:space:]]) ]] &&  local _platform="ubuntu"

  read -rep "2FA User name to create or modify: " username



  if ! cat "/etc/passwd" | awk -F ':' '{print $1}'| grep "${username}" 1>/dev/null 2>&1; then
    __echo "Creaing new user \"${username}\""
    if [[ "${_platform}" == "rhel" ]]; then
      __run adduser --shell /bin/bash "${username}"
    else
      __run adduser --shell /bin/bash --gecos \"\" "${username}"
    fi
    passwd "${username}"
  fi

  if ! groups "${username}" | awk -F ':' '{print $2}' | grep "${_SSH_GROUP}" 1>/dev/null 2>/dev/null; then 
    __echo "Adding user \"${username}\" to the group \"${_SSH_GROUP}\""
    __run usermod -a -G "${_SSH_GROUP}" "${username}"
  fi

  if ! groups "${username}" | awk -F ':' '{print $2}' | grep "${_2FA_GROUP}" 1>/dev/null 2>/dev/null; then 
    __echo "Adding user \"${username}\" to the group \"${_2FA_GROUP}\""
    __run usermod -a -G "${_2FA_GROUP}" "${username}"
  fi

  local user_home=$(cat "/etc/passwd"| grep "^${username}:"|awk -F ':' '{print $6}')
  __echo "User home path: ${user_home}"

  [[ -f "${user_home}/.google_authenticator" ]] && { __echo "WARN" "OTP already configured"; return 1; }

  google-authenticator --force --time-based --disallow-reuse --qr-mode=none --emergency-codes=8 --no-confirm\
    --issuer="SSHD FluffyContainers Scripts"\
    --rate-limit=3 --rate-time=30\
    --window-size=17\
    --secret="${user_home}/.google_authenticator"

  __run chown "${username}":"${username}" "${user_home}/.google_authenticator"
}

[[ ${UID} -ne 0 ]] && { __echo "ERROR" "Script should be executed with root permissions only"; exit 1; }

while true; do
  echo -ne "\033[2J"
  moveCursor 0 0
  clear 1>/dev/null 2>/dev/null
  menu "Configure SSHd,Configure Login Alert,Configure SSHGuard for SSHd,Create or Modify User,Create or Modify 2FA User,Exit" "SSHD Hardening"
  case "$?" in 
    0)  install;;
    1)  install_login_alert;;
    2)  configure_sshguard;;
    3)  configure_user;;
    4)  configure_2fa;;
    5) break;;
    *)  __echo "ERROR" "User canceled";;
  esac
  echo -e "\n\nPress any key to back to menu..."
  readKey 1>/dev/null
done