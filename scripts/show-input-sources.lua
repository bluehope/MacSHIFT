-- Run this from the Hammerspoon Console on each Mac.
-- Hammerspoon exposes source IDs through layouts(true) and methods(true).
local lines = {}
local function append(kind, provider)
    local ok, sources = pcall(provider, true)
    if not ok or type(sources) ~= "table" then return end
    for key, value in pairs(sources) do
        local text
        if type(value) == "table" then
            text = tostring(value.id or value.sourceID or value.sourceId or value.name or value)
        else
            text = tostring(value)
        end
        table.insert(lines, kind .. " " .. tostring(key) .. " = " .. text)
    end
end

append("layout", hs.keycodes.layouts)
append("method", hs.keycodes.methods)
table.sort(lines)
for _, line in ipairs(lines) do print(line) end
hs.alert.show("Input source list printed to Console")
