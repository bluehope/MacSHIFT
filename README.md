# MacSHIFT

**Mac IME synchronization for remote typing.**

MacSHIFT keeps macOS input sources aligned between two Macs during a remote session. It currently synchronizes Korean 2-set and ABC input sources without a network service, SSH, clipboard access, or text capture.

[한국어 안내](#한국어) · [Website source](docs/)

> Status: Korean/English support is ready. Japanese and Chinese are documented as a future CJK extension, not as a current feature.

## What it supports

- Screen Sharing, Jump Desktop, and other Mac-to-Mac tools that forward keyboard events.
- `local`, `remote`, and `both` roles. The installer detects Jump Desktop Viewer and Connect when present.
- `Ctrl+Option+H` for Korean (Hangul), `Ctrl+Option+L` for English (Latin), and Right Shift for a local-state toggle.
- Hammerspoon installation through Homebrew when available, plus a daily opt-out-able update check.

## Install

### Clone (recommended)

```sh
git clone https://github.com/bluehope/MacSHIFT.git
cd MacSHIFT
./install.sh
```

### One command

```sh
curl -fsSL https://raw.githubusercontent.com/bluehope/MacSHIFT/main/bootstrap.sh | sh
```

The bootstrap downloads the latest tagged release and verifies its SHA-256 checksum before running the installer. Review the script before using a pipe-to-shell installation.

After installation, grant **Hammerspoon** Accessibility permission in **System Settings → Privacy & Security → Accessibility**, then reload Hammerspoon:

```lua
hs.reload()
```

## Use

On a Mac installed as `local` or `both`:

- `Ctrl+Option+H` — set local and active remote session to Korean
- `Ctrl+Option+L` — set local and active remote session to English
- `Right Shift` — toggle Korean/English; when a supported remote desktop app is frontmost, synchronize it too

The remote Mac receives `F18` for Korean and `F19` for English. Install it with `--role remote` or `--role both`.

```sh
./install.sh --role local
./install.sh --role remote
./install.sh --role both
```

When no role is provided, Viewer-only selects `local`, Connect-only selects `remote`, and a Mac with both defaults to `both`.

## Updates and configuration

MacSHIFT installs a daily LaunchAgent update check by default. It downloads only tagged GitHub Releases and verifies the supplied SHA-256 checksum. Disable it during installation with `--no-auto-update`.

```sh
./install.sh --check-update
./install.sh --update
```

Your settings live at `~/.config/macshift/config.lua`; installed defaults live beside it in `config.defaults.lua`. Defaults are merged with your settings, so new options can be added without overwriting your role, Source IDs, or shortcuts.

To identify a different input source ID, run this in Hammerspoon Console:

```lua
dofile("/path/to/MacSHIFT/scripts/show-input-sources.lua")
```

## Troubleshooting

- **No shortcut response:** grant Accessibility permission, run `hs.reload()`, then check for a conflicting shortcut.
- **Remote source does not change:** make the remote desktop app frontmost, verify `F18`/`F19` are forwarded, and install `remote` or `both` on the other Mac.
- **Update problem:** inspect `~/.local/state/macshift/update.log`; run `./install.sh --update` manually after fixing network access.

## Privacy and security

MacSHIFT does not open a listener, send keystrokes to a service, read clipboard data, or record typed text. The optional updater contacts GitHub once per day to check the latest public release. See [LICENSE](LICENSE) for usage terms.

## Development

```sh
sh -n install.sh bootstrap.sh scripts/update.sh
luac -p hammerspoon/ime_sync.lua config.defaults.lua config.example.lua
lua tests/test_ime_sync.lua
sh tests/test_release_tools.sh
```

---

## 한국어

MacSHIFT는 원격으로 접속한 두 Mac의 macOS 입력 소스를 맞춰 주는 도구입니다. 현재는 두벌식 한국어와 ABC 영어를 지원합니다. Screen Sharing, Jump Desktop처럼 키보드 이벤트를 전달하는 Mac 간 원격 접속 도구에서 사용할 수 있습니다.

### 설치

```sh
git clone https://github.com/bluehope/MacSHIFT.git
cd MacSHIFT
./install.sh
```

또는 태그된 릴리스를 검증해 설치합니다.

```sh
curl -fsSL https://raw.githubusercontent.com/bluehope/MacSHIFT/main/bootstrap.sh | sh
```

설치 뒤 **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**에서 Hammerspoon을 허용하고 Hammerspoon Console에서 `hs.reload()`를 실행합니다.

### 사용

- `Ctrl+Option+H`: 한글(Hangul)로 지정
- `Ctrl+Option+L`: 영어(Latin)로 지정
- `Right Shift`: 로컬 한/영 토글. 원격 앱이 앞에 있으면 원격에도 동기화

원격 Mac은 `F18`(한글), `F19`(영어) 신호를 받습니다. 접속하는 Mac은 `--role local`, 접속받는 Mac은 `--role remote`, 양쪽 역할을 모두 쓸 Mac은 `--role both`로 설치할 수 있습니다.

기본값으로 하루 한 번 새 GitHub Release를 확인해 검증 후 갱신합니다. 원하지 않으면 `./install.sh --no-auto-update`을 사용하세요. 사용자가 바꾼 설정은 `~/.config/macshift/config.lua`에 보존됩니다.

원본 작업 사양과 CJK 확장 설계는 배포 기능과 분리되어 있으며, 현재 공개 지원 범위는 KO/EN입니다.
