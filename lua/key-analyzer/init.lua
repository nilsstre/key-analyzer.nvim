local main = require("key-analyzer.main")
local config = require("key-analyzer.config")

local KeyAnalyzer = {}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function KeyAnalyzer.show(mode, prefix)
    if _G.KeyAnalyzer.config == nil then
        _G.KeyAnalyzer.config = config.options
    end

    main.show_keyboard_map(mode, prefix)
end

-- setup KeyAnalyzer options and merge them with user provided ones.
function KeyAnalyzer.setup(opts)
    _G.KeyAnalyzer.config = config.setup(opts)

    -- Define a command
    if
        _G.KeyAnalyzer.config.command_name ~= nil
        and _G.KeyAnalyzer.config.command_name ~= ""
        and _G.KeyAnalyzer.config.command_name ~= false
    then
        -- vim.api.nvim_create_user_command(_G.KeyAnalyzer.config.command_name, function()
        --   require("key-analyzer").toggle()
        -- end, {})
        vim.api.nvim_create_user_command(_G.KeyAnalyzer.config.command_name, function(opts)
            local args = vim.split(opts.args, " ")
            local prefix = args[1]
            local mode = args[2] or "n" -- Default to normal mode if not specified

            if prefix == "" then
                vim.notify(
                    "Please specify a prefix (e.g., '<M-', '<C-', '<leader>', 'm', etc)",
                    vim.log.levels.ERROR
                )
                return
            end

            -- Validate mode
            local valid_modes =
                { n = true, v = true, x = true, s = true, o = true, i = true, t = true, c = true }
            if not valid_modes[mode] then
                vim.notify(
                    "Invalid mode specified. Valid modes: n, v, x, s, o, i, t, c",
                    vim.log.levels.ERROR
                )
                return
            end

            if prefix == "leader" then
                prefix = "<leader>"
            end
            if prefix == "<C-w>" then
                -- ToDo: Implement similar behaviour to: https://github.com/folke/which-key.nvim/blob/8badb359f7ab8711e2575ef75dfe6fbbd87e4821/lua/which-key/plugins/presets.lua#L111
                vim.notify(
                    "Built in mappings for <C-w> will not show as they are not returned by :maps"
                )
            end
            if prefix == "z" then
                vim.notify(
                    "Built in mappings for folds will not show as they are not returned by :maps"
                )
            end

            main.show_keyboard_map(mode, prefix)
        end, {
            nargs = "+",
            desc = "Analyze keyboard mappings for a specific prefix and mode",
            complete = function(arglead, cmdline)
                local args = vim.split(cmdline, " ")
                if #args <= 2 then -- Completing prefix
                    -- You can use a lot more, but this is just examples of what you can do
                    return {
                        "<M-",
                        "<C-",
                        "<leader>",
                        "<leader>x",
                        "x",
                        "<C-w>",
                        "<C-w>x",
                        -- Add more common prefixes here
                    }
                else -- Completing mode
                    return { "n", "v", "x", "s", "o", "i", "t", "c" }
                end
            end,
        })
    end
end

_G.KeyAnalyzer = KeyAnalyzer

return _G.KeyAnalyzer
