return {
    -- local: 접속하는 쪽, remote: 접속받는 쪽, both: 양쪽 역할 모두
    role = "local",
    abcSourceID = "com.apple.keylayout.ABC",
    -- 이 컴퓨터의 HIToolbox 설정에서 확인한 두벌식 Source ID입니다.
    -- 다른 Mac에서 다르면 설치 시 --korean-source-id로 덮어쓸 수 있습니다.
    koreanSourceID = "com.apple.inputmethod.Korean.2SetKorean",
    remoteDesktopBundleIDs = {
        "com.p5sys.jump.mac.viewer", -- Jump Desktop Viewer
        "com.apple.ScreenSharing", -- macOS Screen Sharing
    },
    localShortcuts = {
        -- 기본 조합: H = Hangul(한국어), L = Latin(영어). Option은 Hammerspoon에서 alt입니다.
        ko = { "ctrl", "alt", "H" },
        en = { "ctrl", "alt", "L" },
    },
    -- Hammerspoon key name은 공식 map 표기에 맞춰 소문자로 둡니다.
    signalKeys = { ko = "f18", en = "f19" },
    signalModifiers = {},
    showAlerts = true,
    signalDelaySeconds = 0.10,
    debounceSeconds = 0.35,
    capsLockEnabled = false,
    -- 현재 입력 소스를 기준으로 KO/EN을 토글합니다.
    toggleShortcut = { "rightshift" },
    -- 다른 예시:
    -- toggleShortcut = { "rightoption" },
    -- toggleShortcut = { "ctrl", "alt", "space" },
    -- toggleShortcut = false, -- 토글 단축키 끄기
}
