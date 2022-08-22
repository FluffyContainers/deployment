#!/bin/bash

# how to install:
# 1. copy this to the /usr/local/bin
# 2. add to /etc/pam.d/sshd:
#     session    optional     pam_exec.so seteuid /usr/local/bin/login_report.sh
_SERVER="[SERVER]"

# How to get an link:
# 1. Navigate to https://chat.google.com
# 2. Create new space
# 3. From the space menu -> Manage webhooks
# 4. Assing new Name & select avatar
# 5. Copy link on the final step here
_CHAT_LINK='[CHAT-LINK]'
_DATE=$(date +"%Y-%m-%d %T")

# shellcheck disable=SC2206
_CONNECTION=(${SSH_CONNECTION})

if [[ "x${_CHAT_LINK}" != "x" ]]; then
 curl -H 'Content-Type: application/json' -s -m 3 -t 3 -X POST "${_CHAT_LINK}" \
   --data "
     {
        \"text\": \"[${_DATE}] [${_SERVER}] PAM event \'${PAM_TYPE}\' for user \'${PAM_USER}\' via connection: ${_CONNECTION[0]} => ${_CONNECTION[2]}\"
     }" 1>/dev/null 2>/dev/null &
fi
exit 0
