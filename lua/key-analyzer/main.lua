local keyboards = require("key-analyzer.keyboards")

-- internal methods
local main = {}

local current_maps = {}

-- Row offsets for realistic keyboard layout
local ROW_OFFSETS = {
    0,
    1,
    2,
    3,
}

-- Get all keymaps for a specific mode and prefix
local function get_modified_maps(mode, prefix)
    local maps = {}
    local keymap_list = vim.api.nvim_get_keymap(mode)

    -- Convert leader to actual key if needed
    local search_prefix = prefix
    if prefix:match("^<leader>") then
        search_prefix = vim.g.mapleader .. prefix:sub(9)
    end

    -- Escape special characters for pattern matching
    local pattern_prefix = vim.pesc(search_prefix)

    print(vim.inspect(pattern_prefix))
    for _, keymap in ipairs(keymap_list) do
        local lhs = keymap.lhs
        -- Check if the mapping starts with our prefix
        if lhs:match("^" .. pattern_prefix .. "(%w)") then
            local key = lhs:match("^" .. pattern_prefix .. "(%w)")
            maps[key:lower()] = keymap.desc
                or keymap.rhs
                or "[" .. (keymap.callback and "Lua" or "Unknown") .. "]"
        end

        -- Also check literal leader key if prefix contains <leader>
        if
            prefix:match("^<leader>")
            and lhs:match("^<leader>" .. pattern_prefix:sub(#vim.g.mapleader + 1) .. "(%w)")
        then
            local key = lhs:match("^<leader>" .. pattern_prefix:sub(#vim.g.mapleader + 1) .. "(%w)")
            maps[key:lower()] = keymap.desc
                or keymap.rhs
                or "[" .. (keymap.callback and "Lua" or "Unknown") .. "]"
        end
    end

    return maps
end

-- Create a visual representation of the keyboard
local function create_keyboard_visual(maps, mode, modifier)
    local lines = {}
    local highlights = {}
    local config_highlights = _G.KeyAnalyzer.config.highlights

    if config_highlights.define_default_highlights then
        -- Create highlight groups for mapped and unmapped keys
        vim.cmd([[highlight KeyAnalyzerBracketUsed guifg=#aadd00 guibg=#333333 gui=bold]]) -- Mapped brackets (green)
        vim.cmd([[highlight KeyAnalyzerLetterUsed guifg=#ffff00 guibg=#333333 gui=bold]]) -- Mapped letter (yellow)
        vim.cmd([[highlight KeyAnalyzerBracketUnused guifg=#444444 gui=none]]) -- Unmapped brackets (dark gray)
        vim.cmd([[highlight KeyAnalyzerLetterUnused guifg=#888888 gui=none]]) -- Unmapped letter (light gray)
        vim.cmd([[highlight KeyAnalyzerPromo guifg=#444444 gui=none]]) -- Unmapped brackets (dark gray)
    end

    -- Add mode and modifier info line
    local mode_info = {
        n = "Normal",
        v = "Visual",
        x = "Visual Block",
        s = "Select",
        o = "Operator-pending",
        i = "Insert",
        t = "Terminal",
        c = "Command",
    }

    local keyboard = keyboards.get_keyboard(
        _G.KeyAnalyzer.config.keyboard.language,
        _G.KeyAnalyzer.config.keyboard.layout
    )

    local width = 0

    for row_idx, row in ipairs(keyboard) do
        local line = string.rep(" ", math.floor(ROW_OFFSETS[row_idx])) -- Apply offset
        local line_start = #lines + 1

        local new_width = (#row * 3) + 1

        width = math.max(width, new_width)

        for _, key in ipairs(row) do
            local mapping = maps[key]
            local pos = #line + 1
            if mapping then
                -- Highlight positions for mapped key (brackets and letter)
                table.insert(
                    highlights,
                    { group = config_highlights.bracket_used, pos = { line_start, pos, 1 } }
                ) -- Left bracket
                table.insert(
                    highlights,
                    { group = config_highlights.letter_used, pos = { line_start, pos + 1, 1 } }
                ) -- Letter
                table.insert(
                    highlights,
                    { group = config_highlights.bracket_used, pos = { line_start, pos + 2, 1 } }
                ) -- Right bracket
            else
                -- Highlight positions for unmapped key (brackets and letter)
                table.insert(
                    highlights,
                    { group = config_highlights.bracket_unused, pos = { line_start, pos, 1 } }
                ) -- Left bracket
                table.insert(
                    highlights,
                    { group = config_highlights.letter_unused, pos = { line_start, pos + 1, 1 } }
                ) -- Letter
                table.insert(
                    highlights,
                    { group = config_highlights.bracket_unused, pos = { line_start, pos + 2, 1 } }
                ) -- Right bracket
            end
            line = line .. "[" .. key .. "]"
        end

        table.insert(lines, line)
    end

    -- Add mode info after keyboard layout
    table.insert(lines, "") -- Empty line
    table.insert(lines, string.format("Mode: %s", mode_info[mode] or mode:upper()))
    table.insert(lines, string.format("Key: %s", modifier == "leader" and "<leader>" or modifier))
    table.insert(lines, "") -- Empty line

    -- Shameless plug :(
    table.insert(lines, "For more vim: https://x.com/OtivDev")
    table.insert(highlights, { group = config_highlights.promo_highlight, pos = { 9, 0, 50 } })

    table.insert(lines, "") -- Empty line

    return lines, highlights, width
end

-- Get key at cursor position
local function get_key_at_cursor()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1]
    local col = cursor[2] + 1 -- Convert to 1-based index

    -- Only check keyboard layout lines (1-4)
    if line < 1 or line > 4 then
        return nil
    end

    -- Calculate offset for this row
    local offset = ROW_OFFSETS[line]

    -- Adjust column for offset
    col = col - offset

    -- Each key takes 3 positions [k]
    local key_idx = math.floor((col - 1) / 3)

    local keyboard = keyboards.get_keyboard(
        _G.KeyAnalyzer.config.keyboard.language,
        _G.KeyAnalyzer.config.keyboard.layout
    )

    -- Check if we're within a key bracket
    if key_idx >= 0 and key_idx < #keyboard[line] then
        return keyboard[line][key_idx + 1]
    end

    return nil
end

-- Display the keyboard map in a floating window
local function show_in_float(lines, highlights, maps, width)
    local buf = vim.api.nvim_create_buf(false, true)
    local height = #lines + 2

    -- Configure buffer
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    -- vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

    -- Create window first so we can apply highlights

    -- Calculate centered position
    local ui = vim.api.nvim_list_uis()[1]
    local win_opts = {
        relative = "editor",
        width = width,
        height = height,
        col = (ui.width - width) / 2,
        row = (ui.height - height) / 2,
        style = "minimal",
        border = "rounded",
    }

    -- Create and configure window
    local win = vim.api.nvim_open_win(buf, true, win_opts)
    vim.api.nvim_win_set_option(win, "winblend", 0)

    vim.o.wrap = true

    -- Apply highlights
    for _, hl in ipairs(highlights) do
        vim.fn.matchaddpos(hl.group, { hl.pos })
    end

    -- Add empty line for mapping display
    table.insert(lines, "")
    table.insert(lines, "Hover over a key to see its mapping")

    -- Close on q or <Esc>
    vim.keymap.set("n", "q", ":close<CR>", { buffer = buf, silent = true })
    vim.keymap.set("n", "<Esc>", ":close<CR>", { buffer = buf, silent = true })

    -- Set up cursor moved autocmd
    vim.api.nvim_create_autocmd("CursorMoved", {
        buffer = buf,
        callback = function()
            local key = get_key_at_cursor()
            if key then
                local mapping = maps[key]
                local msg = mapping and ("Mapping: " .. key .. " -> " .. mapping)
                    or "No mapping for key: " .. key
                vim.api.nvim_buf_set_lines(buf, -2, -1, false, { msg })
            else
                vim.api.nvim_buf_set_lines(
                    buf,
                    -2,
                    -1,
                    false,
                    { "Hover over a key to see its mapping" }
                )
            end
        end,
    })
end

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
--
---@param mode string: internal identifier for logging purposes.
---@param prefix string: internal identifier for logging purposes.
---@private
function main.show_keyboard_map(mode, prefix)
    current_maps = get_modified_maps(mode, prefix)
    local visual, highlights, width = create_keyboard_visual(current_maps, mode, prefix)
    show_in_float(visual, highlights, current_maps, width)
end

return main
