#!/usr/bin/env bash
set -e
set -u
set -o pipefail

# our script root dir
root_path=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# read app path from command line
: "${app_path:=${1:-}}"
if [ -z "$app_path" ]; then
    echo "ERROR: Must pass path to repository of an app (any version/fork of EasyDiffusion or Stable-Diffusion-UI) to run." >&2
    exit 1
fi
shift 1
if [ ! -d "$app_path" ]; then
    echo "ERROR: Given app path does not exist." >&2
    exit 1
fi

real_app_path=$(readlink -f "$app_path")

cd "$root_path"

# check if this is an app we added as a submodule
if git submodule status "${real_app_path}" >/dev/null 2>/dev/null; then
    # this is a submodule of ours we can check out ourselves!
    git submodule init "$app_path"
    git submodule update "$app_path"
fi

# now let's set up the stage for the app
cd "$app_path"
"$root_path/scripts/setup-venv.sh" "$@"
