# JotNotes

JotNotes is a minimalistic note taking plugin for neovim plugin written in lua.
JotNotes gives you quick access to your notes, weather you need to form a todo
list, jot down some quick thoughts you want to remember for later, take meeting
notes or just develop an idea through writing it out in a temporary file.

If you have used obsidian or a similar local first note taking app, and all you
need is the basic note taking and searching functionality without the bloat,
then you can have this in JotNotes without ever leaving neovim.

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

> [!tip]
> If you like the plugin and want to support me, send me your funniest joke
> through github issues.

> [!warning]
> I might ban you if it's really bad.
