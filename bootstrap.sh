#!/bin/sh
# Downloads and verifies a tagged MacSHIFT release, then runs its installer.
set -eu

repository="bluehope/MacSHIFT"
api_url="${MACSHIFT_RELEASE_API:-https://api.github.com/repos/$repository/releases/latest}"
release_base="${MACSHIFT_RELEASE_BASE:-https://github.com/$repository/releases/download}"
mode="install"

usage() {
    echo "Usage: $0 [--check-update|--update] [installer options]" >&2
    exit 2
}

case "${1:-}" in
    --check-update) mode="check"; shift ;;
    --update) mode="update"; shift ;;
    --help|-h) usage ;;
esac

command -v curl >/dev/null 2>&1 || { echo "MacSHIFT requires curl." >&2; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "MacSHIFT requires tar." >&2; exit 1; }
command -v shasum >/dev/null 2>&1 || { echo "MacSHIFT requires shasum." >&2; exit 1; }

release_json="$(curl -fsSL "$api_url")" || { echo "Could not query the latest MacSHIFT release." >&2; exit 1; }
tag="$(printf '%s' "$release_json" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[ -n "$tag" ] || { echo "Latest release did not contain a tag name." >&2; exit 1; }

installed_version_file="${MACSHIFT_HOME:-$HOME}/.config/macshift/VERSION"
installed_version=""
[ -f "$installed_version_file" ] && installed_version="$(cat "$installed_version_file")"

if [ "$mode" = "check" ]; then
    if [ "$installed_version" = "${tag#v}" ]; then
        echo "MacSHIFT is up to date ($tag)."
    else
        echo "Latest MacSHIFT release: $tag${installed_version:+ (installed: v$installed_version)}"
    fi
    exit 0
fi

if [ "$mode" = "update" ] && [ "$installed_version" = "${tag#v}" ]; then
    echo "MacSHIFT is already up to date ($tag)."
    exit 0
fi

archive="MacSHIFT-$tag.tar.gz"
checksum="$archive.sha256"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/macshift.XXXXXX")"
cleanup() { rm -rf "$temp_dir"; }
trap cleanup EXIT HUP INT TERM

curl -fsSL "$release_base/$tag/$archive" -o "$temp_dir/$archive"
curl -fsSL "$release_base/$tag/$checksum" -o "$temp_dir/$checksum"
(cd "$temp_dir" && shasum -a 256 -c "$checksum") || {
    echo "MacSHIFT release checksum verification failed." >&2
    exit 1
}

tar -xzf "$temp_dir/$archive" -C "$temp_dir"
release_install="$(find "$temp_dir" -type f -name install.sh -print | head -1)"
[ -n "$release_install" ] || { echo "MacSHIFT release archive is invalid." >&2; exit 1; }

exec sh "$release_install" "$@"
