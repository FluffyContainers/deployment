#!/bin/bash

# shellcheck disable=SC2155,SC2015,SC2183

declare -A _COLOR=(
    [UNSELECTED]="\033[38;05;188m"
    [SELECTED]="\033[38;05;232;48;05;188m"
    [RESET]="\033[m"
)

moveCursor() {
    echo -ne "\033[$(($2+1));$1f"  # or tput cup "$2" "$1"
}

getCurrentPos(){
    # shellcheck disable=SC2162
    IFS=';' read -sdR -p $'\E[6n' _row _col; echo "${_col} ${_row#*[}"
}

readKey(){
    read -rsN 1 _key; printf %d "'${_key}"   # %x for hex
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
    local keyCode=(0); local pos=0; local oldPos=0

    drawMenu "menuItems" "${pos}" "${menuTitle}"
    local startPos=$(getCurrentPos); local startPos="${startPos#* }"

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
                if [[ ${keyCode[2]} -eq 49 ]]; then
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
            "27 27") return 255;; # 2 presses of ESC
        esac
        [[ ${pos} -lt 0 ]] && local pos=0
        [[ ${pos} -ge ${#menuItems[*]} ]] && local pos=$((${#menuItems[*]} - 1))

        redrawMenuItems "menuItems" "${startPos}" "${pos}" "${oldPos}"  
    done

    return "${pos}"
}


menu "Menu Item 0,Menu Item 1,Menu Item 2,Menu item 3,Menu item 4" "Title Here"

case "$?" in 
    0) echo "selected 0";;
    1) echo "selected 1";;
    2) echo "selected 2";;
    3) echo "selected 3";;
    4) echo "selected 4";;
    255) echo "user cancel";;
esac
