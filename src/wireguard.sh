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


# [template]

install(){
  echo "System base conf deployment script. "
  echo -en "${_COLOR[ERROR]}You're about to deploy System base conf on current system. ${_COLOR[RESET]}"
  ! __ask "Agree to continue" && return 1

  __echo "Downloading file ${_file}: "
  # shellcheck disable=SC2086
  curl -f ${_follow_link} --progress-bar "${_url}" -o "${_dest_path}" 2>&1
  local _ret=$?

  __download "${__SYSTEM_DOWLOAD_URL}/sysctl.d/system.conf" "/etc/sysctl.d/system.conf"
  __download "${__SYSTEM_DOWLOAD_URL}/dev/10-persistent-net.rules" "/etc/udev/rules.d/10-persistent-net.rules"
}

install