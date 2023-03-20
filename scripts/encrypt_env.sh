#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

#
# Add to this list for new keys to be encrypted. Regex is used here.
#
# Any key ends with the following words will be encrypted.
#
# For example if you want to encrypt a new key/value pair:
#
# TEST_ACCOUNT=test@example.com
#
# adding "_ACCOUNT" to the list will encrypt all keys ending with _ACCOUNT 
# like SAMPLE_ACCOUNT and TEST_ACCOUNT
#
keys_to_encrypt="_EMAIL|_PASSWORD|_USER|_KEY|_SECRET|_API_TOKEN|_API_UID"

check_envar() {
    local public_key="${1}"
    local private_key_file="${2}"
    if [ -z "${!public_key-}"  ] && [ -z "${!private_key_file-}" ]; then 
        printf "ERROR: Please define either environment variable '${public_key}' or '${private_key_file}'\n\n"
        exit 1
    fi
}

check_envar "SOPS_AGE_RECIPIENTS" "SOPS_AGE_KEY_FILE"

if [ -z "${1-}" ]; then
    printf "ERROR: input file missing\n\n"
    exit 1
fi

dirname=$(dirname -- "$1")
filename=$(basename -- "$1")
extension="${filename##*.}"
filename="${filename%.*}"

output_file="$dirname/$filename.enc.$extension"

declare age_public_key

if [ -n "${SOPS_AGE_RECIPIENTS-}" ]; then
    echo "Using SOPS_AGE_RECIPIENTS env var"
    age_public_key="${SOPS_AGE_RECIPIENTS}"
elif [ -n "${SOPS_AGE_KEY_FILE-}" ] && [ ! -f "${SOPS_AGE_KEY_FILE-}" ]; then
    printf "ERROR: SOPS_AGE_KEY_FILE not found in the file system: ${SOPS_AGE_KEY_FILE}\n\n"
    exit 1
elif [ -n "${SOPS_AGE_KEY_FILE-}" ]; then
    echo "Using SOPS_AGE_KEY_FILE env var"
    age_public_key=$(cat $SOPS_AGE_KEY_FILE | grep -oP "public key: \K(.*)")
fi

if [ -f $output_file ]; then
    read -p "Warning: This will overwrite your existing $output_file, continue? [y/N] " prompt
    if [[ ! $prompt =~ [yY](es)* ]]; then
        exit 1
    fi
fi

sops --encrypt --age $age_public_key --input-type dotenv --output-type dotenv \
                --encrypted-regex ".*($keys_to_encrypt)$" $1 > $output_file

printf "Output file: $output_file\n\n"