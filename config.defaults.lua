return {
    -- local: controller, remote: receiver, both: both roles on this Mac
    role = "local",
    abcSourceID = "com.apple.keylayout.ABC",
    koreanSourceID = "com.apple.inputmethod.Korean.2SetKorean",
    remoteDesktopBundleIDs = {
        "com.p5sys.jump.mac.viewer", -- Jump Desktop Viewer
        "com.apple.ScreenSharing", -- macOS Screen Sharing
    },
    localShortcuts = {
        ko = { "ctrl", "alt", "H" },
        en = { "ctrl", "alt", "L" },
    },
    signalKeys = { ko = "f18", en = "f19" },
    signalModifiers = {},
    showAlerts = true,
    signalDelaySeconds = 0.10,
    debounceSeconds = 0.35,
    capsLockEnabled = false,
    rightShiftEnabled = true,
}
