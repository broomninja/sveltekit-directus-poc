#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

check_envar() {
    local private_key_file="${1}"
    if [ -z "${!private_key_file-}" ]; then 
        printf "ERROR: Please define environment variable '${private_key_file}'\n\n"
        exit 1
    fi
}

check_envar "SOPS_AGE_KEY_FILE"

if [ -z "${1-}" ]; then
    printf "ERROR: input file missing\n\n"
    exit 1
fi

dirname=$(dirname -- "$1")
filename=$(basename -- "$1")
extension="${filename##*.}"
filename="${filename%%.*}"

output_file="$dirname/$filename.$extension"

if [ -n "${SOPS_AGE_KEY_FILE-}" ] && [ ! -f "${SOPS_AGE_KEY_FILE-}" ]; then
    printf "ERROR: SOPS_AGE_KEY_FILE not found in the file system: ${SOPS_AGE_KEY_FILE}\n\n"
    exit 1
elif [ -n "${SOPS_AGE_KEY_FILE-}" ]; then
    echo "Using SOPS_AGE_KEY_FILE env var"
fi


if [ -f $output_file ]; then
    read -p "Warning: This will overwrite your existing $output_file, continue? [y/N] " prompt
    if [[ ! $prompt =~ [yY](es)* ]]; then
        exit 1
    fi
fi

sops --decrypt --input-type dotenv --output-type dotenv $1 > $output_file

printf "Output file: $output_file\n\n"
