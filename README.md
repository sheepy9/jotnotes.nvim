# JotNotes

JotNotes is a minimalistic note taking plugin for neovim written in lua.
JotNotes gives you quick access to your notes, weather you need to form a todo
list, jot down some quick thoughts you want to remember for later, take meeting
notes or just develop an idea through writing it out in a temporary file.

If you have used obsidian or a similar local first note taking app, and all you
need is the basic note taking and searching functionality without the bloat,
then JotNotes can give you this without ever leaving neovim.

**Features**:
- regular notes
- dailies
- scratchpad file with archiving
- telescope integration for finding notes
- telescope integration for live grepping

## Installation

With Lazy
```lua
{
    'sheepy9/jotnotes.nvim',
    opts = {
        dir = "$HOME/Documents/jotnotes/",
        archive_scratch_on_clear = true
    }
}
```

## User Commands

The plugin defines the following user commands that you can call directly

- `JotSearch` - opens telescope file finder in the JotNotes directory
- `JotSearch` - opens telescope live grep in the JotNotes directory
- `JotNew filename` - creates a new note with the given name in the JotNotes directory
- `JotToday` - opens (or creates) the daily note for today
- `JotScratch` - opens the current scratchpad file
- `JotScratchNew` - clears (or archives) the current scratchpad file and creates a new one
- `JotLastNote` - opens last opened note in split or floating window

## Default Keybindings

By default, JotNotes creates the following keybindings for the UserCommands

```lua
    vim.keymap.set('n', '<leader>Jf', "<cmd>JotSearch<cr>", { desc = 'Find jot note' })
    vim.keymap.set('n', '<leader>Jt', "<cmd>JotGrep<cr>", { desc = 'Search text in jot notes' })
    vim.keymap.set('n', '<leader>Jn',
        function()
            local filename = vim.fn.input("Enter filename: ")
            if filename == "" then
                filename = fsutil.generate_timestamp().."-note"
            end
            M.createJotNote(filename)
        end, { desc = 'Create new note' })
    vim.keymap.set('n', '<leader>Jd', "<cmd>JotToday<cr>", { desc = 'Go to (or create) daily note' })
    vim.keymap.set('n', '<leader>Js', "<cmd>JotScratch<cr>", { desc = 'Go to scratchpad' })
    vim.keymap.set('n', '<leader>JS', "<cmd>JotScratchNew<cr>", { desc = 'Create new scratchpad' })
    vim.keymap.set('n', '<leader>Jl', "<cmd>JotLastNote<cr>", { desc = 'Open most recent note' })
```

## Misc

> [!tip]
> If you like the plugin and want to support me, send me your funniest joke
> through github issues.

> [!warning]
> I might ban you if it's really bad.
