#!/bin/sh
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/macshift-tests.XXXXXX")"
cleanup() { rm -rf "$temp_dir"; }
trap cleanup EXIT HUP INT TERM

sh -n "$root/install.sh" "$root/bootstrap.sh" "$root/scripts/update.sh" "$root/scripts/release.sh"
sh "$root/scripts/release.sh" --output "$temp_dir"
archive="$temp_dir/MacSHIFT-v$(cat "$root/VERSION").tar.gz"
checksum="$archive.sha256"
[ -f "$archive" ] && [ -f "$checksum" ]
(cd "$temp_dir" && shasum -a 256 -c "$(basename "$checksum")")
tar -tzf "$archive" | grep -q "MacSHIFT-v$(cat "$root/VERSION")/install.sh"
if tar -tzf "$archive" | grep -q 'JumpDesktop_Mac_IME_Sync_Spec.md'; then
    echo 'private specification was included in release archive' >&2
    exit 1
fi
echo 'Release tool tests passed'
