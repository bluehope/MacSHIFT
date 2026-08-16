return {
    -- local: 접속하는 쪽, remote: 접속받는 쪽, both: 양쪽 역할 모두
    role = "local",
    -- ABC is preferred when both ABC and U.S. are enabled; otherwise U.S. is used.
    -- Change the order to prefer U.S., or add another enabled English layout.
    englishSourceIDs = {
        "com.apple.keylayout.ABC",
        "com.apple.keylayout.US",
    },
    -- 이 컴퓨터의 HIToolbox 설정에서 확인한 두벌식 Source ID입니다.
    -- 다른 Mac에서 다르면 설치 시 --korean-source-id로 덮어쓸 수 있습니다.
    koreanSourceID = "com.apple.inputmethod.Korean.2SetKorean",
    remoteDesktopBundleIDs = {
        "com.p5sys.jump.mac.viewer", -- Jump Desktop Viewer
        "com.apple.ScreenSharing", -- macOS Screen Sharing
    },
    imeShortcuts = {
        -- 기본 조합: H = Hangul(한국어), L = Latin(영어). Option은 Hammerspoon에서 alt입니다.
        korean = { "ctrl", "alt", "H" },
        english = { "ctrl", "alt", "L" },
        -- 현재 입력 소스를 기준으로 KO/EN을 토글합니다.
        toggle = { "rightshift" },
        -- 다른 예시:
        -- toggle = { "rightoption" },
        -- toggle = { "ctrl", "alt", "space" },
        -- toggle = false, -- 토글 단축키 끄기
    },
    -- Hammerspoon key name은 공식 map 표기에 맞춰 소문자로 둡니다.
    signalKeys = { ko = "f18", en = "f19" },
    signalModifiers = {},
    showAlerts = true,
    signalDelaySeconds = 0.04,
    debounceSeconds = 0.15,
}
