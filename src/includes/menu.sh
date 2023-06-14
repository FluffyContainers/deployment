#!/bin/bash

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

# [start]
# options: optional


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
# [end]