return {
    -- CLI labels: local = this Mac connects; remote = the other Mac receives; both = either direction
    role = "local",
    abcSourceID = "com.apple.keylayout.ABC",
    koreanSourceID = "com.apple.inputmethod.Korean.2SetKorean",
    remoteDesktopBundleIDs = {
        "com.p5sys.jump.mac.viewer", -- Jump Desktop Viewer
        "com.apple.ScreenSharing", -- macOS Screen Sharing
    },
    imeShortcuts = {
        korean = { "ctrl", "alt", "H" },
        english = { "ctrl", "alt", "L" },
        toggle = { "rightshift" },
    },
    signalKeys = { ko = "f18", en = "f19" },
    signalModifiers = {},
    showAlerts = true,
    signalDelaySeconds = 0.10,
    debounceSeconds = 0.35,
}
