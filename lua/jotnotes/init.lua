local M = {}

local fsutil = require('jotnotes.fsutil')
local winutil = require('jotnotes.winutil')

local function get_scratch_title()
    return "# Scratch (from " .. fsutil.generate_timestamp("%Y/%m/%d %H:%M:%S") .. ")\n\n"
end

local lastFunction = function()
    vim.api.nvim_command('JotSearch')
end

--- Create homepage file and scratch buffer
---@param directory string path to directory
local function initialize_jotnotes_directory(directory)
    local index_text = [[
# JotNotes

Welcome to jotnotes. This is the home page for your notes. You can use it as a
wayfinder for your other notes, or place the most important stuff here, such as
reminders, links to dailies, impartant todos or anything else you want quick
access to.

For example, my notes home page is full of "that's what she said" jokes, so that
I can quickly use them to lighten the tension when things get sort of hard.
                                                          ᵗʰᵃᵗ'ˢ ʷʰᵃᵗ ˢʰᵉ ˢᵃᶦᵈ
]]

    local scratch_text = get_scratch_title()

    scratch_text = scratch_text .. [[
This is the scratchpad file. It can be used to jot down quick thoughts, to work
out some problem by breaking it down and for other transient text. Scratch notes
can be archived when cleared by simply specifying the option `archive_scratch_on_clear`
in the plugin configuration.
]]
    fsutil.create_file_with_text(directory .. "index.md", index_text)
    fsutil.create_file_with_text(directory .. "scratch.md", scratch_text)
end

--- Function to merge user options with default options
---@param user_opts table user defined options
---@return table merged table with user_opts priority
local function merge_options(user_opts, default_opts)
    local opts = vim.tbl_deep_extend("force", {}, default_opts, user_opts or {})
    return opts
end



M.default_config = {
    dir = "$HOME/Documents/jotnotes/",
    archive_scratch_on_clear = true,
    floating_window_opts = {
        style = 'minimal',
        relative = 'editor',
        width = 81,
        height = "80%",
        vertical_alignment = "center",
        horizontal_alignment = "center",
        vertical_offset = 0,
        horizontal_offset = 0,
        border = 'rounded',
        autoclose = true
    }
}

M.config = {}

--- Main plugin setup table
---@param user_config table containing user configuration
function M.setup(user_config)
    if user_config == nil or type(next(user_config)) == "nil" then
        M.config = M.default_config
    else
        M.config = merge_options(user_config, M.default_config)
    end

    M.config.dir = fsutil.expand_env_var(M.config.dir)

    local directory_existed = fsutil.ensure_directory_exists(M.config.dir)
    M.config.dir = fsutil.normalize_path(M.config.dir)
    if not directory_existed then
        vim.notify("[JotNotes] | Created jotnotes root directory at " .. M.config.dir, vim.log.levels.INFO)
        initialize_jotnotes_directory(M.config.dir)
    end

    M.createUserCommands()
    M.setupDefaultKeymap()
end

function M.findJotNote()
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    require('telescope.builtin').find_files({
        prompt_title = "<C-f> floating | <C-h> horizontal | <C-v> vertical",
        cwd = M.config.dir,
        hidden = true,
        attach_mappings = function(prompt_bufnr, map)
            map('i', '<C-f>', function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                winutil.open_floating_window(selection.path, M.config.floating_window_opts)

                lastFunction = function()
                    winutil.open_floating_window(selection.path, M.config.floating_window_opts)
                end
            end)
            map('i', '<C-h>', function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                winutil.open_horizontal_split(selection.path, M.config.split_opts)

                lastFunction = function()
                    winutil.open_horizontal_split(selection.path, M.config.split_opts)
                end
            end)
            map('i', '<C-v>', function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                lastFunction = function()
                    winutil.open_vertical_split(selection.path, M.config.split_opts)
                end
            end)

            return true
        end

    })
end

function M.grepJotNote()
    require('telescope.builtin').live_grep({
        prompt_title = "Search Text in " .. M.config.dir,
        cwd = M.config.dir,
        hidden = true,

        attach_mappings = function(prompt_bufnr, map)
            map('i', '<C-f>', function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                winutil.open_floating_window(selection.path, M.config.floating_window_opts)
            end)
            map('i', '<C-h>', function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                print("You pressed Ctrl-f on: " .. selection.path)
            end)
            map('i', '<C-v>', function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                print("You pressed Ctrl-f on: " .. selection.path)
            end)

            return true
        end
    })
end

function M.createJotNote(filename)
    local note_name = filename
    if not fsutil.match_file_extension(filename, "md") then
        note_name = filename .. ".md"
    end
    if not fsutil.file_exists(M.config.dir .. note_name) then
        fsutil.create_file_with_text(M.config.dir .. note_name, "# " .. note_name)
    end
    vim.cmd('edit ' .. M.config.dir .. note_name)
end

function M.createUserCommands()
    vim.api.nvim_create_user_command('JotSearch',
        function()
            M.findJotNote()
        end,
        {})
    vim.api.nvim_create_user_command('JotGrep',
        function()
            M.grepJotNote()
        end,
        {})

    vim.api.nvim_create_user_command('JotNew',
        function(opts)
            M.createJotNote(opts.args)
            lastFunction = function() M.createJotNote(opts.args) end
        end,
        {
            nargs = 1,
            complete = fsutil.file_completion(M.config.dir), -- returns function
        })

    vim.api.nvim_create_user_command('JotToday',
        function()
            local dailies_path = M.config.dir .. "dailies/"
            fsutil.ensure_directory_exists(dailies_path)
            M.createJotNote("dailies/" .. fsutil.generate_timestamp("%Y-%m-%d-%a"))
            lastFunction = function() M.createJotNote("dailies/" .. fsutil.generate_timestamp("%Y-%m-%d-%a")) end
        end,
        {})

    vim.api.nvim_create_user_command('JotScratch',
        function()
            M.createJotNote("scratch.md")
            lastFunction = function() M.createJotNote("scratch.md") end
        end,
        {})

    vim.api.nvim_create_user_command('JotScratchNew',
        function()
            if M.config.archive_scratch_on_clear then
                local archived_path = M.config.dir .. "archive/"
                local archived_filename = archived_path .. fsutil.generate_timestamp("%Y%m%d%H%M%S") .. "-scratch.md"
                fsutil.ensure_directory_exists(archived_path)
                fsutil.copy_file(M.config.dir .. "scratch.md", archived_filename)
                vim.notify("[JotNotes] | Scratch file archived to " .. archived_filename, vim.log.levels.INFO)
            end
            local scratch_path = M.config.dir .. "scratch.md"
            fsutil.create_file_with_text(scratch_path, get_scratch_title())
            -- reopen note
            vim.api.command('edit ' .. scratch_path)
            lastFunction = function() vim.api.command('edit ' .. scratch_path) end
        end,
        {})

    vim.api.nvim_create_user_command('JotLastNote',
        function()
            lastFunction()
        end,
        {})
end

function M.setupDefaultKeymap()
    vim.keymap.set('n', '<leader>Jf', "<cmd>JotSearch<cr>", { desc = 'Find jot note' })
    vim.keymap.set('n', '<leader>Jt', "<cmd>JotGrep<cr>", { desc = 'Search text in jot notes' })
    vim.keymap.set('n', '<leader>Jn',
        function()
            local filename = vim.fn.input("Enter filename: ")
            if filename == "" then
                filename = fsutil.generate_timestamp() .. "-note"
            end
            M.createJotNote(filename)
        end, { desc = 'Create new note' })
    vim.keymap.set('n', '<leader>Jd', "<cmd>JotToday<cr>", { desc = 'Go to (or create) daily note' })
    vim.keymap.set('n', '<leader>Js', "<cmd>JotScratch<cr>", { desc = 'Go to scratchpad' })
    vim.keymap.set('n', '<leader>JS', "<cmd>JotScratchNew<cr>", { desc = 'Create new scratchpad' })
    vim.keymap.set('n', '<leader>Jl', "<cmd>JotLastNote<cr>", { desc = 'Open most recent note' })
end

return M
