#!/bin/sh
set -eu

package_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/macshift"
mkdir -p "$state_dir"

exec "$package_dir/bootstrap.sh" --update >>"$state_dir/update.log" 2>&1
