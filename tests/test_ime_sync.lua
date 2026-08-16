-- Lightweight unit tests using a small Hammerspoon API mock.
-- Run: lua tests/test_ime_sync.lua

local failures = 0
local function check(condition, message)
    if not condition then
        failures = failures + 1
        io.stderr:write("FAIL: " .. message .. "\n")
    end
end

local currentSource = "com.apple.keylayout.ABC"
local alertLog = {}
local sentKeys = {}
local frontmostBundle = "com.p5sys.jump.mac.viewer"
local hotkeys = {}
local eventTapCallback

hs = {
    configdir = ".",
    alert = { show = function(message) table.insert(alertLog, message) end },
    logger = { new = function() return { i = function() end, e = function() end } end },
    timer = {
        secondsSinceEpoch = function() return os.clock() + 1 end,
        doAfter = function(_, callback) callback() end,
    },
    keycodes = {
        map = { f18 = 100, f19 = 101, rightshift = 60 },
        layouts = function() return {
            "com.apple.keylayout.ABC",
        } end,
        methods = function() return { "com.apple.inputmethod.Korean.2SetKorean" } end,
        currentSourceID = function(sourceID)
            if sourceID then currentSource = sourceID end
            return currentSource
        end,
    },
    application = {
        frontmostApplication = function()
            return { bundleID = function() return frontmostBundle end }
        end,
    },
    eventtap = {
        keyStroke = function(modifiers, key)
            table.insert(sentKeys, { modifiers = modifiers, key = key })
        end,
        event = { types = { keyDown = 10, keyUp = 11, flagsChanged = 12 } },
        new = function(_, callback)
            eventTapCallback = callback
            return { start = function() end }
        end,
    },
    hotkey = {
        bind = function(modifiers, key, callback)
            table.insert(hotkeys, { modifiers = modifiers, key = key, callback = callback })
            return {}
        end,
    },
}

local function load(role, toggleBinding, englishSourceIDs)
    if toggleBinding == nil then toggleBinding = false end
    IME_SYNC_CONFIG = {
        role = role,
        englishSourceIDs = englishSourceIDs or { "com.apple.keylayout.ABC", "com.apple.keylayout.US" },
        koreanSourceID = "com.apple.inputmethod.Korean.2SetKorean",
        remoteDesktopBundleIDs = { "com.p5sys.jump.mac.viewer", "com.apple.ScreenSharing" },
        imeShortcuts = {
            korean = { "ctrl", "alt", "H" },
            english = { "ctrl", "alt", "L" },
            toggle = toggleBinding,
        },
        signalKeys = { ko = "f18", en = "f19" },
        signalModifiers = {},
        showAlerts = false,
        debounceSeconds = 0,
        signalDelaySeconds = 0,
    }
    return dofile("hammerspoon/ime_sync.lua")
end

local localAPI = load("local")
check(localAPI.setBoth("KO") == true, "local KO command succeeds")
check(currentSource == "com.apple.inputmethod.Korean.2SetKorean", "local KO selects Korean source")
check(#sentKeys == 1 and sentKeys[1].key == "f18", "local KO sends F18")

local toggleAPI = load("local", { "ctrl", "alt", "space" })
local toggleBinding = hotkeys[#hotkeys]
check(toggleBinding.key == "space", "custom toggle shortcut is bound")
check(#toggleBinding.modifiers == 2, "custom toggle shortcut keeps modifiers")

frontmostBundle = "com.apple.ScreenSharing"
sentKeys = {}
check(localAPI.setBoth("EN") == true, "Screen Sharing is recognized as a remote desktop")
check(#sentKeys == 1 and sentKeys[1].key == "f19", "Screen Sharing sends F19")

frontmostBundle = "com.apple.TextEdit"
local before = #sentKeys
check(localAPI.setBoth("EN") == true, "inactive Jump Desktop still changes local source")
check(#sentKeys == before, "inactive Jump Desktop sends no signal")

frontmostBundle = "com.p5sys.jump.mac.viewer"
sentKeys = {}
local remoteAPI = load("remote")
check(remoteAPI.receive("EN") == true, "remote EN handler succeeds")
check(currentSource == "com.apple.keylayout.ABC", "remote EN selects ABC source")
check(#sentKeys == 0, "remote receiver does not emit a signal")

local originalMethods = hs.keycodes.methods
hs.keycodes.methods = function() return {} end
local invalidAPI = load("remote")
check(invalidAPI.setBoth("KO") == false, "missing Korean source fails")
hs.keycodes.methods = originalMethods

frontmostBundle = "com.p5sys.jump.mac.viewer"
local bothAPI = load("both")
check(bothAPI.setBoth("KO") == true, "both role local command succeeds")
check(#sentKeys == 1 and sentKeys[1].key == "f18", "both role sends F18 through Viewer")

local merged = bothAPI._mergeTables({ nested = { defaultValue = true }, retained = "yes" }, { nested = { userValue = true } })
check(merged.nested.defaultValue == true, "defaults survive config merge")
check(merged.nested.userValue == true, "user values merge into defaults")
check(merged.retained == "yes", "unrelated defaults survive config merge")

frontmostBundle = "com.apple.TextEdit"
local consumed = eventTapCallback({
    getKeyCode = function() return 101 end,
    getType = function() return hs.eventtap.event.types.keyDown end,
})
check(consumed == true, "both role consumes incoming F19 outside Viewer")
check(currentSource == "com.apple.keylayout.ABC", "both role applies incoming EN locally")
check(#sentKeys == 1, "both role receiver does not echo incoming signal")

hs.keycodes.layouts = function() return { "com.apple.keylayout.US" } end
frontmostBundle = "com.apple.TextEdit"
local usAPI = load("local", false)
check(usAPI._englishSourceID() == "com.apple.keylayout.US", "U.S. is selected when ABC is unavailable")
check(usAPI.setLocal("EN") == true, "U.S. English source is accepted")
check(currentSource == "com.apple.keylayout.US", "local EN selects U.S. source")

if failures > 0 then
    io.stderr:write(string.format("%d test(s) failed\n", failures))
    os.exit(1)
end
print("All IME sync unit tests passed")
