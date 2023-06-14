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

__dir(){
  local __source="${BASH_SOURCE[0]}"
  while [[ -h "${__source}" ]]; do
    local __dir=$(cd -P "$( dirname "${__source}" )" 1>/dev/null 2>&1 && pwd)
    local __source="$(readlink "${__source}")"
    [[ ${__source} != /* ]] && local __source="${__dir}/${__source}"
  done
  echo -n "$(cd -P "$( dirname "${__source}" )" 1>/dev/null 2>&1 && pwd)"
}
DIR=$(__dir)


TPL_DIR="${DIR}/src/includes"
REPLACE_DIR="${DIR}/src"

__START_INCLUDE="[template] !!! DO NOT MODIFY CODE INSIDE. INSTEAD USE apply-teplate.sh script to update template !!!"
__END_INCLUDE="[template] [end] !!! DO NOT REMOVE ANYTHING INSIDE, INCLUDING CURRENT LINE !!!"

__START_BLOCK="[start]"
__END_BLOCK="[end]"
__TEMPLATE_PLACEHOLDER="[template]"


generate_template(){
  echo "# ${__START_INCLUDE}"

  # shellcheck disable=SC2094
  for f in "${TPL_DIR}/"*; do
    local _can_copy=0
    while IFS= read -rs line; do
      [[ "${line}" == "# ${__START_BLOCK}" ]] && {
        local _can_copy=1
        echo "# [module: $(basename "${f}")]"
        continue
      }
      [[ "${line}" == "# ${__END_BLOCK}" ]] && local _can_copy=0
      [[ ${_can_copy} -eq 0 ]] && continue
      printf '%s\n' "$line"

    done < "${f}"
  done

  echo "# ${__END_INCLUDE}"
}


number_of_lines(){
  mapfile -t array <<< "$1"
  echo -n ${#array[@]}
}

update_file(){
  local _file="${1}"
  local _template="$2"
  local _can_copy=1
  mapfile -t _content <<< "$(<"${_file}")"

  for line in "${_content[@]}"; do
    if [[ "${line}" == "# ${__TEMPLATE_PLACEHOLDER}" ]]; then
      echo "${_template}"
      continue
    fi

    [[ "${line}" == "# ${__START_INCLUDE}" ]] && local _can_copy=0
    [[ "${line}" == "# ${__END_INCLUDE}" ]] && {
      local _can_copy=1
      echo "${_template}"
      continue
    }
    [[ ${_can_copy} -eq 1 ]] && echo "${line}"
  done
}

update_files(){
  local _template="$1"
  for f in "${REPLACE_DIR}/"*; do
    [[ -d "${f}" ]] && continue

    echo "Updating file: $(basename "${f}") ..."
    local update_content="$(update_file "${f}" "${_template}")"
    echo -n "${update_content}" > "${f}"
  done
}

echo -n "Generating template ... "
IFS= TEMPLATE=$(generate_template)

IFS= __lines=$(number_of_lines "${TEMPLATE}")
echo "${__lines} lines"
update_files "${TEMPLATE}"