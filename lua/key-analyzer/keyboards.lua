local keyboards = {}

local KEYBOARD_LAYOUTS = {
    english = {
        dvorak = {
            { "§", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "[", "]" },
            { "'", ",", ".", "p", "y", "f", "g", "c", "r", "l", "/", "=" },
            { "a", "o", "e", "u", "i", "d", "h", "t", "n", "s", "-", "\\" },
            { "`", ";", "q", "j", "k", "x", "b", "m", "w", "v", "z" },
        },
        us_qwerty = {
            { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" },
            { "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]" },
            { "a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'" },
            { "z", "x", "c", "v", "b", "n", "m", ",", ".", "/" },
        },
    },
    swedish = {
        qwerty = {
            { "§", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "+", "´" },
            { "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "å", "¨" },
            { "a", "s", "d", "f", "g", "h", "j", "k", "l", "ö", "ä", "'" },
            { "<", "z", "x", "c", "v", "b", "n", "m", ",", ".", "-" },
        },
    },
}

--- Get keyboard layout.
--- Throws and error if either language or layout is unknown.
---@param language string keyboard language
---@param layout string keyboard layout
---@return table
function keyboards.get_keyboard(language, layout)
    local keyboard_layouts = KEYBOARD_LAYOUTS[language]

    assert(keyboard_layouts ~= nil, string.format("%s is not a reconized language", language))

    local keyboard_layout = keyboard_layouts[layout]

    assert(
        keyboard_layout ~= nil,
        string.format("%s is not a reconized keyboard layout for %s", layout, language)
    )

    return keyboard_layout
end

return keyboards
