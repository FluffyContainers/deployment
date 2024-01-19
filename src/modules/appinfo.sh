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
_OS_TYPE=$(grep "^ID=" /etc/os-release | sed 's/ID=//')
_OS_VERSION=$(grep "^VERSION_ID=" /etc/os-release | sed 's/VERSION_ID=//')

# shellcheck disable=SC2120
info_header(){
    local __inject_rows_func="${1}"
    __echo "------"
    __echo "OS                    : ${_OS_TYPE} ${_OS_VERSION}"
    __echo "Platform              : ${_PLATFORM_TYPE}"
    __echo "Application           : ${APP}"
    __echo "Base Install Dir      : ${HOME}"
    if [[ -n "${__inject_rows__func}" ]]; then
    __echo ""
     ${__inject_rows__func}
    fi
    __echo "------"
}

# [end]