#!/usr/bin/env bash
set -e

declare -a paths
index=0

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-west-2}
export PAGERDUTY_TOKEN=${PAGERDUTY_TOKEN:-validate}

for file_with_path in "$@"; do
  paths[index]=$(dirname "$file_with_path")
  let "index+=1"
done

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  if [[ -n "$(find "$path_uniq" -maxdepth 1 -name '*.tf' -print -quit)" ]]; then
    pushd "$path_uniq" > /dev/null
    terraform init -backend=false
    terraform validate
    popd > /dev/null
   fi
done
