#!/bin/sh
# Build the two assets uploaded to a tagged GitHub Release.
set -eu

source_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
version="$(cat "$source_dir/VERSION")"
tag="v$version"
output_dir="$source_dir/dist"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --output) [ "$#" -ge 2 ] || exit 2; output_dir="$2"; shift 2 ;;
        --tag) [ "$#" -ge 2 ] || exit 2; tag="$2"; shift 2 ;;
        --help|-h) echo "Usage: $0 [--tag vX.Y.Z] [--output DIRECTORY]"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done

[ "$tag" = "v$version" ] || { echo "Tag $tag does not match VERSION $version." >&2; exit 1; }
git -C "$source_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo 'release.sh requires a Git work tree.' >&2; exit 1; }

mkdir -p "$output_dir"
archive="$output_dir/MacSHIFT-$tag.tar.gz"
checksum="$archive.sha256"
git -C "$source_dir" archive --format=tar --prefix="MacSHIFT-$tag/" HEAD | gzip -n > "$archive"
(cd "$output_dir" && shasum -a 256 "$(basename "$archive")" > "$(basename "$checksum")")
echo "$archive"
echo "$checksum"
