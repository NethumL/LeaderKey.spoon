--- === LeaderKey ===
---
--- Vim-like Leader key
local obj = {}
obj.__index = obj

-- Metadata
obj.name = "LeaderKey"
obj.version = "0.1"
obj.author = "Nethum Lamahewage"
obj.homepage = "https://github.com/NethumL/LeaderKey.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- LeaderKey.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new("LeaderKey")

--- LeaderKey.helperId
--- Variable
--- ID of currently shown helper
obj.helperId = nil

--- LeaderKey.escapeKey
--- Variable
--- Key combination to abort
obj.escapeKey = { "", "escape" }

--- LeaderKey.helperDelay
--- Variable
--- Delay in seconds before showing helper
obj.helperDelay = 0.2

--- LeaderKey.helperRowLimit
--- Variable
--- Maximum number of rows in helper
obj.helperRowLimit = 5

--- LeaderKey.helperItemSize
--- Variable
--- Maximum size of one item in helper
obj.helperItemSize = 15

--- LeaderKey.helperTextStyle
--- Variable
--- Styling for text
obj.helperTextStyle = {
    atScreenEdge = 2,
    textStyle = {
        font = {
            name = "monospace",
            size = 18,
        },
    },
}

--- LeaderKey.helperSpecialKeys
--- Variable
--- Representations for special keys
obj.helperSpecialKeys = {
    space = "SPC",
}

obj.modifierToSymbolMap = {
    command = "⌘",
    control = "⌃",
    option = "⌥",
    shift = "⇧",
}

local timer
local currentKeyMap

local function max(a, b)
    if a > b then
        return a
    end
    return b
end

local function table_contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

local function string_length(str)
    local length = string.len(str)
    if string.find(str, "⌥") then
        length = length - 2
    end
    return length
end

local function padString(str, total, side)
    local length = string_length(str)
    if length < total then
        if side == 0 then
            return str .. string.rep(" ", total - length)
        elseif side == 1 then
            return string.rep(" ", total - length) .. str
        end
    end
    return str
end

local function getUppercaseKey(key)
    local upperCaseMap = {
        ["`"] = "~",
        ["1"] = "!",
        ["2"] = "@",
        ["3"] = "#",
        ["4"] = "$",
        ["5"] = "%",
        ["6"] = "^",
        ["7"] = "&",
        ["8"] = "*",
        ["9"] = "(",
        ["0"] = ")",
        ["-"] = "_",
        ["="] = "+",
        ["["] = "}",
        ["]"] = "}",
        ["\\"] = "|",
        [";"] = ":",
        ["'"] = '"',
        [","] = "<",
        ["."] = ">",
        ["/"] = "?",
    }

    if string_length(key) > 1 then
        return key
    end

    local ascii = string.byte(key)
    if ascii >= 97 and ascii <= 122 then
        return string.upper(key)
    end

    if upperCaseMap[key] then
        return upperCaseMap[key]
    else
        return key
    end
end

--- LeaderKey.singleKey(key, name)
--- Function
--- Returns a table with modifier, key, and name for a single key
--- Parameters:
---  * key - Key to bind
---  * name - Name of keybinding
--- Returns:
---  * Table with modifier, key, and name
--- Notes:
--- If the key is a capital letter, it also includes the shift modifier.
--- Otherwise, no modifiers.
function obj.singleKey(key, name)
    local mod = {}
    if key == getUppercaseKey(key) and string.len(key) == 1 then
        mod = { "shift" }
        key = string.lower(key)
    end

    if name then
        return { mod, key, name }
    else
        return { mod, key, "no name" }
    end
end

local function compareKeys(a, b)
    -- Handle space
    local has_space_a = a[2] == "space"
    local has_space_b = b[2] == "space"
    if has_space_a and has_space_b then
        return #a[1] > #b[1]
    elseif has_space_a then
        return true
    elseif has_space_b then
        return false
    end

    local asciiA = string.byte(a[2])
    local asciiB = string.byte(b[2])
    if table_contains(a[1], "shift") then
        asciiA = asciiA + 0.5
    end
    if table_contains(b[1], "shift") then
        asciiB = asciiB + 0.5
    end
    return asciiA < asciiB
end

local function parseModString(str)
    local result = {}
    str = string.lower(str)
    local function find(ps)
        for _, s in ipairs(ps) do
            if string.find(str, s, 1, true) then
                result[#result + 1] = ps[1]
                return
            end
        end
    end
    find({ "cmd", "command", "⌘" })
    find({ "ctrl", "control", "⌃" })
    find({ "alt", "option", "⌥" })
    find({ "shift", "⇧" })
    return result
end

local function transformKeyMap(keyMap)
    local result = {}
    for trigger, action in hs.fnutils.sortByKeys(keyMap, compareKeys) do
        if type(action) ~= "function" then
            action = transformKeyMap(action)
        end
        table.insert(result, { key = trigger, action = action })
    end

    return result
end

local function generateKeyString(trigger)
    local text = ""
    if type(trigger[1]) == "string" then
        trigger[1] = parseModString(trigger[1])
    end

    local key = trigger[2]

    if trigger[1] ~= {} then
        for _, mod in ipairs(trigger[1]) do
            local upper = getUppercaseKey(key)
            if mod == "shift" and key ~= upper then
                key = upper
            else
                text = text .. obj.modifierToSymbolMap[mod] .. "+"
            end
        end
    end

    if obj.helperSpecialKeys[key] ~= nil then
        key = obj.helperSpecialKeys[key]
    end
    text = text .. key

    return text
end

local function generateHelper(keyMap)
    local helperText = ""

    local texts = {}
    for _, value in ipairs(keyMap) do
        table.insert(texts, { key = generateKeyString(value.key), name = value.key[3] })
    end

    local n = #texts
    local rows
    if n < obj.helperRowLimit then
        rows = n
    else
        rows = obj.helperRowLimit
    end
    local cols = n // rows
    local extra = n % rows

    local stringSizes = {}
    for j = 1, cols + 1 do
        stringSizes[j] = { key = 5, name = 3 }
    end

    for i = 1, rows do
        for j = 1, cols + 1 do
            if j == cols + 1 and i >= extra then
                break
            end
            local current = texts[(j - 1) * rows + i]
            stringSizes[j].key = max(stringSizes[j].key, string_length(current.key))
            stringSizes[j].name = max(stringSizes[j].name, string_length(current.name))
        end
    end

    for i = 1, rows do
        for j = 1, cols + 1 do
            if j == cols + 1 and i > extra then
                break
            end
            local current = texts[(j - 1) * rows + i]
            helperText = helperText
                .. padString(
                    padString(current.key, stringSizes[j].key, 1)
                        .. " -> "
                        .. padString(current.name, stringSizes[j].name, 0),
                    obj.helperItemSize,
                    0
                )
        end
        helperText = helperText .. "\n"
    end

    return helperText
end

local function showHelper()
    local helperText = generateHelper(currentKeyMap)
    obj.helperId = hs.alert.show(helperText, obj.helperTextStyle, true)
end

local function killHelper()
    if obj.helperId then
        hs.alert.closeSpecific(obj.helperId)
        obj.helperId = nil
    end
    timer:stop()
end

local function bindRecursively(keyMap)
    if type(keyMap) == "function" then
        return keyMap
    end

    local modal = hs.hotkey.modal.new()

    modal:bind(obj.escapeKey[1], obj.escapeKey[2], function()
        modal:exit()
        killHelper()
    end)

    for _, value in ipairs(keyMap) do
        modal:bind(value.key[1], value.key[2], function()
            modal:exit()
            killHelper()
            bindRecursively(value.action)()
        end)
    end

    return function()
        modal:enter()
        killHelper()
        currentKeyMap = keyMap
        timer:start()
    end
end

--- LeaderKey.getBinder(userKeyMap)
--- Function
--- Prepares the top level keybindings in the keymap
--- Parameters:
---  * userKeyMap - A keymap to load to the leader key binding
--- Returns:
---  * Function that runs when the leader key is triggered
--- Notes:
--- Spec of keymap:
--- Every key is of format {{modifers}, key, description}.
--- The first two elements are similar to what is expected in `hs.hotkey.bind`
---
--- The value for each must be in one of the following two forms:
--- 1. A function: pressing the key invokes the function.
--- 2. A table: pressing the key activates the next layer of keybindings.
---    This table should have the same format as the top table
---
--- For example:
---
--- ```lua
--- local keyMap = {
---     [{ {}, "space", "command" }] = functionToRunForSpace,
---     [{ { "option" }, "space", "⌥-SPC" }] = functionToRunForOptionSpace,
---     [singleKey("h", "hammerspoon+")] = {
---         [singleKey("r", "reload")] = function()
---             hs.reload()
---             hs.console.clearConsole()
---         end,
---        [singleKey(";", "console")] = function()
---            hs.toggleConsole()
---        end,
---     },
--- }
--- ```
function obj.getBinder(userKeyMap)
    -- Get keyMap into right format, along with sorting
    local keyMap = transformKeyMap(userKeyMap)

    -- Prepare hs.timer.delayed object
    timer = hs.timer.delayed.new(obj.helperDelay, showHelper)

    -- Bind keys
    return bindRecursively(keyMap)
end

return obj
