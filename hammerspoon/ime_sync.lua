-- MacSHIFT: Mac IME synchronization for remote Mac sessions.
-- Loaded by ~/.hammerspoon/init.lua on either the local or remote Mac.

local function mergeTables(defaults, overrides)
    local merged = {}
    for key, value in pairs(defaults or {}) do
        if type(value) == "table" then
            merged[key] = mergeTables(value, {})
        else
            merged[key] = value
        end
    end
    for key, value in pairs(overrides or {}) do
        if type(value) == "table" and type(merged[key]) == "table" then
            merged[key] = mergeTables(merged[key], value)
        else
            merged[key] = value
        end
    end
    return merged
end

local function loadConfig()
    local supplied = rawget(_G, "IME_SYNC_CONFIG")
    if supplied then return supplied end

    local configPath = rawget(_G, "IME_SYNC_CONFIG_PATH")
    local defaultsPath = rawget(_G, "IME_SYNC_DEFAULTS_PATH")
    if not configPath then configPath = (hs.configdir or "") .. "/macshift/config.lua" end
    if not defaultsPath then defaultsPath = (hs.configdir or "") .. "/macshift/config.defaults.lua" end

    local defaultsOK, defaults = pcall(dofile, defaultsPath)
    local configOK, config = pcall(dofile, configPath)
    if configOK and type(config) == "table" then
        return mergeTables(defaultsOK and defaults or {}, config)
    end

    hs.alert.show("MacSHIFT config not found")
    return defaultsOK and defaults or {}
end

local config = loadConfig()
local log = hs.logger.new("macshift", config.logLevel or "warning")
local lastActionAt = 0
local started = false
local api = {}
local activeEventTaps = {}

local function isLocalRole()
    return config.role == "local" or config.role == "both"
end

local function isRemoteRole()
    return config.role == "remote" or config.role == "both"
end

local function notify(message, isError)
    if isError or config.showAlerts ~= false then hs.alert.show(message) end
    if isError then log.e(message) else log.i(message) end
end

local function sourceExists(sourceID)
    if type(sourceID) ~= "string" or sourceID == "" then return false end
    local providers = { hs.keycodes.layouts, hs.keycodes.methods }
    for _, provider in ipairs(providers) do
        local ok, sources = pcall(provider, true)
        if ok and type(sources) == "table" then
            for key, value in pairs(sources) do
                if key == sourceID or value == sourceID then return true end
                if type(value) == "table" and
                    (value.id == sourceID or value.sourceID == sourceID or value.sourceId == sourceID) then
                    return true
                end
            end
        end
    end
    return false
end

local function validateSources()
    local missing = {}
    if not sourceExists(config.abcSourceID) then
        table.insert(missing, "ABC: " .. tostring(config.abcSourceID))
    end
    if not sourceExists(config.koreanSourceID) then
        table.insert(missing, "Korean: " .. tostring(config.koreanSourceID))
    end
    if #missing > 0 then
        notify("Input source not found: " .. table.concat(missing, ", "), true)
        return false
    end
    return true
end

local function setSource(sourceID, label)
    if not sourceExists(sourceID) then
        notify("Input source not found: " .. label, true)
        return false
    end
    local ok, result = pcall(hs.keycodes.currentSourceID, sourceID)
    if not ok or result == false then
        notify("Could not set input source: " .. label, true)
        return false
    end
    return true
end

local function isJumpDesktopFrontmost()
    local app = hs.application.frontmostApplication()
    if not app then return false end
    local bundleID = app:bundleID()
    for _, allowed in ipairs(config.jumpDesktopBundleIDs or {}) do
        if bundleID == allowed then return true end
    end
    return false
end

local function debounce()
    local current = hs.timer.secondsSinceEpoch()
    local minimum = tonumber(config.debounceSeconds) or 0.35
    if current - lastActionAt < minimum then return false end
    lastActionAt = current
    return true
end

local function targetDetails(target)
    if target == "KO" then
        return config.koreanSourceID, "KO", config.signalModifiers or {}, (config.signalKeys or {}).ko
    end
    return config.abcSourceID, "EN", config.signalModifiers or {}, (config.signalKeys or {}).en
end

local function sendRemoteSignal(target)
    local _, label, modifiers, key = targetDetails(target)
    if not isJumpDesktopFrontmost() then
        notify("Jump Desktop is not active", true)
        return false
    end
    if type(key) ~= "string" or key == "" then
        notify("Remote signal key is not configured for " .. label, true)
        return false
    end
    local delay = tonumber(config.signalDelaySeconds) or 0.10
    hs.timer.doAfter(delay, function()
        if not isJumpDesktopFrontmost() then
            notify("Jump Desktop became inactive; signal not sent", true)
            return
        end
        hs.eventtap.keyStroke(modifiers, key, 0)
    end)
    return true
end

local function applyTarget(target, notification)
    if target ~= "KO" and target ~= "EN" then
        notify("Unknown IME target: " .. tostring(target), true)
        return false
    end
    if not debounce() or not validateSources() then return false end

    local sourceID, label = targetDetails(target)
    if not setSource(sourceID, label) then return false end
    notify(notification .. label, false)
    return true
end

local function applyRemoteTarget(target)
    return applyTarget(target, "Remote IME → ")
end

function api.receive(target)
    if not isRemoteRole() then
        notify("Remote Receiver is not enabled", true)
        return false
    end
    return applyRemoteTarget(target)
end

function api.setBoth(target)
    if not isLocalRole() then
        notify("Local Controller is not enabled", true)
        return false
    end
    local jumpActive = isJumpDesktopFrontmost()
    local notification = jumpActive and "MacSHIFT → " or "Local IME → "
    if not applyTarget(target, notification) then return false end

    if not jumpActive then
        return true
    end

    return sendRemoteSignal(target)
end

function api.setLocal(target)
    if not isLocalRole() then
        notify("Local Controller is not enabled", true)
        return false
    end
    return applyTarget(target, "Local IME → ")
end

function api.toggleBothFromLocal()
    if not isLocalRole() then
        notify("Local Controller is not enabled", true)
        return false
    end
    local current = hs.keycodes.currentSourceID()
    local target = current == config.koreanSourceID and "EN" or "KO"
    if isJumpDesktopFrontmost() then
        return api.setBoth(target)
    end
    return api.setLocal(target)
end

local function bindHotkey(modifiers, key, callback)
    if type(key) ~= "string" or key == "" then return nil end
    local ok, binding = pcall(hs.hotkey.bind, modifiers or {}, key, callback)
    if not ok or not binding then
        notify("Could not bind " .. tostring(key) .. " (shortcut conflict?)", true)
    end
    return ok and binding or nil
end

local function shortcutParts(spec, fallbackModifiers, fallbackKey)
    if type(spec) ~= "table" or #spec < 2 then
        return fallbackModifiers, fallbackKey
    end
    local key = spec[#spec]
    local modifiers = {}
    for index = 1, #spec - 1 do
        table.insert(modifiers, spec[index])
    end
    return modifiers, key
end

function api.start()
    if started then return true end
    started = true
    validateSources()

    local signalKeys = config.signalKeys or {}
    if config.role == "both" and #(config.signalModifiers or {}) == 0 then
        local keyCodes = {
            ko = hs.keycodes.map[signalKeys.ko],
            en = hs.keycodes.map[signalKeys.en],
        }
        local receiverTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp }, function(event)
            -- While sending from the local controller, let F18/F19 reach Jump Desktop.
            if isJumpDesktopFrontmost() then return false end
            local keyCode = event:getKeyCode()
            local target = keyCode == keyCodes.ko and "KO" or (keyCode == keyCodes.en and "EN" or nil)
            if not target then return false end
            if event:getType() == hs.eventtap.event.types.keyDown then
                api.receive(target)
            end
            return true
        end)
        table.insert(activeEventTaps, receiverTap)
        receiverTap:start()
    else
        bindHotkey(config.signalModifiers, signalKeys.ko, function()
            api.receive("KO")
        end)
        bindHotkey(config.signalModifiers, signalKeys.en, function()
            api.receive("EN")
        end)
    end

    if isLocalRole() then
        local shortcuts = config.localShortcuts or {}
        local ko = shortcuts.ko or { "ctrl", "alt", "H" }
        local en = shortcuts.en or { "ctrl", "alt", "L" }
        local koModifiers, koKey = shortcutParts(ko, { "ctrl", "alt" }, "H")
        local enModifiers, enKey = shortcutParts(en, { "ctrl", "alt" }, "L")
        bindHotkey(koModifiers, koKey, function() api.setBoth("KO") end)
        bindHotkey(enModifiers, enKey, function() api.setBoth("EN") end)

        local rightShiftEnabled = config.rightShiftEnabled
        -- Backward compatibility for configs generated before Right Shift.
        if rightShiftEnabled == nil then rightShiftEnabled = config.rightOptionEnabled end
        if rightShiftEnabled == nil then rightShiftEnabled = config.rightCommandEnabled end
        if rightShiftEnabled then
            local rightShiftKeyCode = hs.keycodes.map.rightshift or 60
            local rightShiftTap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(event)
                if event:getKeyCode() ~= rightShiftKeyCode then
                    return false
                end
                local flags = event:getFlags()
                if flags.shift then
                    api.toggleBothFromLocal()
                end
                return true
            end)
            table.insert(activeEventTaps, rightShiftTap)
            rightShiftTap:start()
        end

        if config.capsLockEnabled then
            local eventtap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
                if event:getKeyCode() ~= 57 or not isJumpDesktopFrontmost() then return false end
                local current = hs.keycodes.currentSourceID()
                api.setBoth(current == config.koreanSourceID and "EN" or "KO")
                return true
            end)
            table.insert(activeEventTaps, eventtap)
            eventtap:start()
        end
    end
    return true
end

api.config = config
api._sourceExists = sourceExists
api._isJumpDesktopFrontmost = isJumpDesktopFrontmost
api._mergeTables = mergeTables

api.start()
return api
