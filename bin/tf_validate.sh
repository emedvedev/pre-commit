#!/usr/bin/env bash
set -e

declare -a paths
local index=0
local error=0

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-west-2}
export PAGERDUTY_TOKEN=${PAGERDUTY_TOKEN:-validate}

for file_with_path in "$@"; do
  paths[index]=$(dirname "$file_with_path")
  let "index+=1"
done

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  if [[ -n "$(find "$path_uniq" -maxdepth 1 -name '*.tf' -print -quit)" ]]; then
    pushd "$path_uniq" > /dev/null
    
    set +e
    init_output=$(terraform init -backend=false 2>&1)
    init_code=$?
    set -e
    if [[ $init_code != 0 ]]; then
      error=1
      echo "Init before validation failed: $path_uniq"
      echo "$init_output"
      popd > /dev/null
      continue
    fi
    
    set +e
    validate_output=$(terraform validate 2>&1)
    validate_code=$?
    set -e

    if [[ $validate_code != 0 ]]; then
      error=1
      echo "Validation failed: $path_uniq"
      echo "$validate_output"
      echo
    fi
    
    popd > /dev/null
   fi
done

if [[ $error -ne 0 ]]; then
  exit 1
fi
