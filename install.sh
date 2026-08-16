#!/bin/sh
set -eu

usage() {
    cat >&2 <<'EOF'
Usage: install.sh [options]
  --role local|remote|both
  --korean-source-id SOURCE_ID
  --jump-bundle-id BUNDLE_ID
  --no-hammerspoon-install
  --no-auto-update
  --check-update
  --update
EOF
    exit 2
}

role=""
korean_source_id=""
jump_bundle_id=""
allow_hammerspoon_install="1"
auto_update="1"
update_mode=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --role) [ "$#" -ge 2 ] || usage; role="$2"; shift 2 ;;
        --korean-source-id) [ "$#" -ge 2 ] || usage; korean_source_id="$2"; shift 2 ;;
        --jump-bundle-id) [ "$#" -ge 2 ] || usage; jump_bundle_id="$2"; shift 2 ;;
        --no-hammerspoon-install) allow_hammerspoon_install="0"; shift ;;
        --no-auto-update) auto_update="0"; shift ;;
        --check-update) update_mode="--check-update"; shift ;;
        --update) update_mode="--update"; shift ;;
        --help|-h) usage ;;
        *) usage ;;
    esac
done

source_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if [ -n "$update_mode" ]; then
    exec sh "$source_dir/bootstrap.sh" "$update_mode"
fi

detect_korean_source_id() {
    detected="$(defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null | awk -F '"' '/"Input Mode" = / && $4 ~ /Korean/ { print $4; exit }')"
    printf '%s' "${detected:-com.apple.inputmethod.Korean.2SetKorean}"
}

bundle_id_for_app() { [ -d "$1" ] && mdls -name kMDItemCFBundleIdentifier -raw "$1" 2>/dev/null || true; }
version_for_app() { [ -d "$1" ] && mdls -name kMDItemVersion -raw "$1" 2>/dev/null || true; }

detect_jump_bundle_id() {
    detected="$(bundle_id_for_app "/Applications/Jump Desktop.app")"
    [ -n "$detected" ] || detected="$(bundle_id_for_app "/Applications/Jump Desktop_Beta.app")"
    printf '%s' "${detected:-com.p5sys.jump.mac.viewer}"
}

detect_role() {
    viewer_present=0; connect_present=0
    { [ -d "/Applications/Jump Desktop.app" ] || [ -d "/Applications/Jump Desktop_Beta.app" ]; } && viewer_present=1
    [ -d "/Applications/Jump Desktop Connect.app" ] && connect_present=1
    if [ "$viewer_present" = 1 ] && [ "$connect_present" = 0 ]; then printf '%s' local; return; fi
    if [ "$viewer_present" = 0 ] && [ "$connect_present" = 1 ]; then printf '%s' remote; return; fi
    if [ -t 0 ]; then
        if [ "$viewer_present" = 1 ] && [ "$connect_present" = 1 ]; then
            printf '%s' 'Both Jump Desktop Viewer and Connect were found. Install role [local/remote/both] (default: both): ' >&2
        else
            printf '%s' 'Jump Desktop role not detected. Install role [local/remote/both] (default: local): ' >&2
        fi
        read -r detected
        case "$detected" in
            remote|both) printf '%s' "$detected" ;;
            ''|local) [ "$viewer_present" = 1 ] && [ "$connect_present" = 1 ] && printf '%s' both || printf '%s' local ;;
            *) echo "Invalid role: $detected" >&2; exit 2 ;;
        esac
        return
    fi
    echo 'Could not detect Jump Desktop role; use --role local, remote, or both.' >&2
    exit 2
}

[ -n "$role" ] || role="$(detect_role)"
case "$role" in local|remote|both) ;; *) usage ;; esac
[ -n "$korean_source_id" ] || korean_source_id="$(detect_korean_source_id)"
[ -n "$jump_bundle_id" ] || jump_bundle_id="$(detect_jump_bundle_id)"

viewer_app=""
[ -d "/Applications/Jump Desktop.app" ] && viewer_app="/Applications/Jump Desktop.app"
[ -z "$viewer_app" ] && [ -d "/Applications/Jump Desktop_Beta.app" ] && viewer_app="/Applications/Jump Desktop_Beta.app"
connect_app=""
[ -d "/Applications/Jump Desktop Connect.app" ] && connect_app="/Applications/Jump Desktop Connect.app"

echo "\n=== MacSHIFT environment check ==="
echo "macOS: $(sw_vers -productVersion) ($(uname -m))"
command -v brew >/dev/null 2>&1 && echo "Homebrew: installed ($(brew --version | head -1))" || echo 'Homebrew: not found'
[ -d "/Applications/Hammerspoon.app" ] && echo "Hammerspoon: installed ($(version_for_app /Applications/Hammerspoon.app))" || echo 'Hammerspoon: NOT INSTALLED'
[ -n "$viewer_app" ] && echo "Jump Desktop Viewer: installed ($(version_for_app "$viewer_app"))" || echo 'Jump Desktop Viewer: not found'
[ -n "$connect_app" ] && echo "Jump Desktop Connect: installed ($(version_for_app "$connect_app"))" || echo 'Jump Desktop Connect: not found'
echo "Role: $role"
echo "Korean Source ID: $korean_source_id"
echo 'Shortcuts: Ctrl+Option+H = Korean (Hangul); Ctrl+Option+L = English (Latin)'
echo 'Right Shift: toggle locally, and synchronize while a remote desktop app is active'

if [ ! -d "/Applications/Hammerspoon.app" ]; then
    if [ "$allow_hammerspoon_install" = 1 ] && command -v brew >/dev/null 2>&1; then
        if [ -t 0 ]; then
            printf '%s' 'Hammerspoon is missing. Install it with Homebrew now? [Y/n]: ' >&2
            read -r install_answer
            case "$install_answer" in n|N) echo 'Hammerspoon installation skipped.' >&2; exit 1;; esac
        fi
        brew install --cask hammerspoon
    fi
    [ -d "/Applications/Hammerspoon.app" ] || { echo 'Install Hammerspoon, allow Accessibility permission, then run this command again.' >&2; exit 1; }
fi

user_home="${MACSHIFT_HOME:-$(dscl . -read /Users/"$(id -un)" NFSHomeDirectory | awk '{print $2}')}"
package_dir="$user_home/.config/macshift"
legacy_dir="$user_home/.config/jump-desktop-ime-sync"
hammerspoon_dir="$user_home/.hammerspoon"
init_file="$hammerspoon_dir/init.lua"
state_dir="${XDG_STATE_HOME:-$user_home/.local/state}/macshift"
agent_dir="$user_home/Library/LaunchAgents"
agent_file="$agent_dir/io.github.bluehope.macshift.updater.plist"

mkdir -p "$package_dir/hammerspoon" "$package_dir/scripts" "$hammerspoon_dir" "$state_dir"
install -m 644 "$source_dir/hammerspoon/ime_sync.lua" "$package_dir/hammerspoon/ime_sync.lua"
install -m 644 "$source_dir/config.defaults.lua" "$package_dir/config.defaults.lua"
install -m 644 "$source_dir/scripts/show-input-sources.lua" "$package_dir/scripts/show-input-sources.lua"
install -m 755 "$source_dir/bootstrap.sh" "$package_dir/bootstrap.sh"
install -m 755 "$source_dir/scripts/update.sh" "$package_dir/scripts/update.sh"
install -m 644 "$source_dir/VERSION" "$package_dir/VERSION"

if [ ! -f "$package_dir/config.lua" ]; then
    if [ -f "$legacy_dir/config.lua" ]; then
        cp "$legacy_dir/config.lua" "$package_dir/config.lua"
        echo "Migrated existing configuration from $legacy_dir"
    else
        sed -e "s/role = \"local\"/role = \"$role\"/" -E -e "s#koreanSourceID = \"[^\"]*\"#koreanSourceID = \"$korean_source_id\"#" -e "s/com.p5sys.jump.mac.viewer/$jump_bundle_id/" "$source_dir/config.example.lua" > "$package_dir/config.lua"
    fi
else
    echo "Keeping user configuration: $package_dir/config.lua"
fi

if [ ! -f "$init_file" ]; then : > "$init_file"; fi
init_tmp="$init_file.macshift-tmp"
awk '
  /^-- BEGIN (Jump Desktop Mac IME Sync|MacSHIFT)$/ { skipping=1; next }
  /^-- END (Jump Desktop Mac IME Sync|MacSHIFT)$/ { skipping=0; next }
  !skipping { print }
' "$init_file" > "$init_tmp"
mv "$init_tmp" "$init_file"
cat >> "$init_file" <<EOF

-- BEGIN MacSHIFT
do
    local macshiftRoot = "$package_dir"
    IME_SYNC_CONFIG_PATH = macshiftRoot .. "/config.lua"
    IME_SYNC_DEFAULTS_PATH = macshiftRoot .. "/config.defaults.lua"
    dofile(macshiftRoot .. "/hammerspoon/ime_sync.lua")
end
-- END MacSHIFT
EOF

if [ "$auto_update" = 1 ]; then
    mkdir -p "$agent_dir"
    cat > "$agent_file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>io.github.bluehope.macshift.updater</string>
  <key>ProgramArguments</key><array><string>$package_dir/scripts/update.sh</string></array>
  <key>StartInterval</key><integer>86400</integer>
  <key>ProcessType</key><string>Background</string>
</dict></plist>
EOF
    if [ "${MACSHIFT_SKIP_LAUNCHCTL:-0}" != 1 ]; then
        launchctl bootout "gui/$(id -u)" "$agent_file" >/dev/null 2>&1 || true
        launchctl bootstrap "gui/$(id -u)" "$agent_file" >/dev/null 2>&1 || echo "Automatic updates were installed but could not be started; log in again or load $agent_file manually." >&2
    fi
else
    [ "${MACSHIFT_SKIP_LAUNCHCTL:-0}" = 1 ] || launchctl bootout "gui/$(id -u)" "$agent_file" >/dev/null 2>&1 || true
    rm -f "$agent_file"
fi

echo "Installed MacSHIFT $(cat "$source_dir/VERSION") to $package_dir"
echo "Hammerspoon loader: $init_file"
echo "Automatic updates: $([ "$auto_update" = 1 ] && echo enabled || echo disabled)"
echo 'Allow Hammerspoon in System Settings > Privacy & Security > Accessibility, then run hs.reload().'
