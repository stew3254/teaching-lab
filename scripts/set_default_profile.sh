#!/usr/bin/env bash

set -e
eval "$(jq -r '@sh "REMOTE=\(.remote) PROFILE=\(.profile) PROJECT=\(.project)"')"
lxc profile show "${REMOTE}:${PROFILE}" --project "${PROJECT}" | lxc profile edit "${REMOTE}:default" --project "${PROJECT}"
echo '{}'