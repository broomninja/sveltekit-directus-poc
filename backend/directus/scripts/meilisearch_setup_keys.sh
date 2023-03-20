#!/bin/sh

# 
# Script to call meilisearch API endpoint to create "search" and "admin" api keys
# upon containers start up
#
# using /bin/sh instead of /bin/bash, default directus docker image uses alpine so does not have bash installed
#

# commented errexit flag as we want to capture timeout error code
#set -o errexit
set -o nounset

script_name=$(basename "${0##*/}")
search_host="search"
search_port="7700"

# make sure env vars are set before we proceed, script will exit if any of them are not set due to nounset flag
echo $MEILI_MASTER_KEY > /dev/null
echo $MEILI_SEARCH_API_UID > /dev/null
echo $MEILI_ADMIN_API_UID > /dev/null

wait_for_ready () {
    echo "Testing: $1"
    # if jq cannot be installed, use grep instead
    #timeout -s TERM 10s sh -c \
    #    'while [ "$(curl -k -s -m 3 -L ${0} | grep -o '"'"'"status": *"[^"]*'"'"' | grep -o '"'"'[^"]*$'"'"')" != "available" ];\
    timeout -s TERM 10s sh -c \
        'while [ "$(curl -k -s -m 3 -L ${0} | jq -r '.status')" != "available" ];\
        do echo "Waiting for ${0}" && sleep 1;\
        done' ${1}
    TIMEOUT_RETURN="$?"
    #echo "${TIMEOUT_RETURN}"
    if [ "$TIMEOUT_RETURN" = 0 ] 
    then
        printf "OK: ${1}\n\n"
        return
    elif [ "${TIMEOUT_RETURN}" = 124 ] 
    then
        printf "TIMEOUT: ${1} -> EXIT\n\n"
        exit "${TIMEOUT_RETURN}"
    else
        printf "Other error with code ${TIMEOUT_RETURN}: ${1} -> EXIT\n\n"
        exit "${TIMEOUT_RETURN}"
    fi
}

# Wait until meilisearch has started, the /health api will return the following when its ready: 
# 
# {"status":"available"}
#
wait_for_ready http://${search_host}:${search_port}/health

# Create Search Key using the preset uid
curl -s -o /dev/null \
  -X POST "http://${search_host}:${search_port}/keys" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${MEILI_MASTER_KEY}" \
  --data-binary '{
    "uid": "'"${MEILI_SEARCH_API_UID}"'",
    "name": "Directus Search API Key",
    "description": "Use it to search from the frontend webapp",
    "actions": ["search"],
    "indexes": ["*"],
    "expiresAt": null
  }'

# Create Admin Key using the preset uid
curl -s -o /dev/null \
  -X POST "http://${search_host}:${search_port}/keys" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${MEILI_MASTER_KEY}" \
  --data-binary '{
    "uid": "'"${MEILI_ADMIN_API_UID}"'",
    "name": "Directus Admin API Key",
    "description": "Use it for anything that is not a search operation. Caution! Do not expose it on a public frontend",
    "actions": ["*"],
    "indexes": ["*"],
    "expiresAt": null
  }'
