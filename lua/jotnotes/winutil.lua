local M = {}

M.buffer = nil
M.window = nil


local function parse_width(len)
    if type(len) == 'number' then
        return len
    elseif type(len) == 'string' then
        local numberString = len:match("^(%d+)%%$")

        if numberString then
            return math.floor(vim.o.columns * tonumber(numberString) / 100)
        else
            vim.notify("[JotNotes] | Invalid percentage format", vim.log.levels.ERROR)
        end
        return numberString
    else
        vim.notify("[JotNotes] | Invalid window size format given", vim.log.levels.WARN)
        return 50
    end
end

local function parse_height(len)
    if type(len) == 'number' then
        return len
    elseif type(len) == 'string' then
        local numberString = len:match("^(%d+)%%$")

        if numberString then
            return math.floor(vim.o.lines * tonumber(numberString) / 100)
        else
            vim.notify("[JotNotes] | Invalid percentage format", vim.log.levels.ERROR)
        end
        return numberString
    else
        vim.notify("[JotNotes] | Invalid window size format given", vim.log.levels.WARN)
        return 50
    end
end

local function calculate_topleft(opts)
    local w = parse_width(opts.width)
    local h = parse_height(opts.height)
    local vo = opts.vertical_offset
    local ho = opts.horizontal_offset

    local row = 0
    local col = 0
    if opts.vertical_alignment == "center" then
        row = (math.floor((vim.o.lines - h) / 2)) + vo
    elseif opts.vertical_alignment == "top" then
        row = vo
    elseif opts.vertical_alignment == "bottom" then
        row = math.floor(vim.o.lines - h) + vo - 4
    else
        vim.notify("[JotNotes] | Invalid vertical_alignment option", vim.log.levels.WARN)
    end

    if opts.horizontal_alignment == "center" then
        col = math.floor((vim.o.columns - w) / 2) + ho
    elseif opts.horizontal_alignment == "left" then
        col = ho + 2
    elseif opts.horizontal_alignment == "right" then
        col = math.floor(vim.o.columns - w) + ho - 2
    else
        vim.notify("[JotNotes] | Invalid horizontal_alignment option", vim.log.levels.WARN)
    end


    return { x = col, y = row }
end

local function close_buffer_if_not_edited(buf)
    if buf == nil then return end
    if not vim.api.nvim_buf_is_valid(buf) then
        print("Buffer is not valid.")
        return
    end

    local is_modified = vim.api.nvim_buf_get_option(buf, 'modified')
    if not is_modified then
        vim.api.nvim_buf_delete(buf, { force = true })
    else
        -- Buffer is modified, so we won't delete it
        print("Buffer has unsaved changes and was not closed.")
    end
end

function M.open_horizontal_split(file_path, opts)
    vim.api.nvim_command('split')
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_win_set_buf(win, buf)

    vim.api.nvim_command('resize '..parse_height(opts.height))
    vim.api.nvim_command('edit ' .. file_path)
end

function M.open_vertical_split(file_path, opts)
    vim.api.nvim_command('vsplit')
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_win_set_buf(win, buf)

    vim.api.nvim_command('vertical resize '..parse_width(opts.width))
    vim.api.nvim_command('edit ' .. file_path)
end

function M.open_floating_window(file_path, opts)
    M.close_floating_window()

    M.buffer = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_option(M.buffer, 'bufhidden', 'wipe')
    -- Define the size and position of the floating window
    -- local width = math.floor(vim.o.columns * 0.75)
    local height = parse_height(opts.height)
    local width = parse_width(opts.width)
    -- local height = math.floor(vim.o.lines * 0.75)
    -- local width = 81
    local topleft = calculate_topleft(opts)

    local row = topleft.y
    local col = topleft.x
    -- Define the window options
    local win_opts = {
        style = opts.style,
        relative = opts.relative,
        width = width,
        height = height,
        row = row,
        col = col,
        border = opts.border
    }
    -- Open the floating window
    M.window = vim.api.nvim_open_win(M.buffer, true, win_opts)
    -- Optionally, set some content in the buffer
    --
    vim.api.nvim_set_current_buf(M.buffer)

    vim.api.nvim_command('edit ' .. file_path)
    vim.wo.signcolumn = "yes"

    if opts.autoclose then
        vim.api.nvim_create_autocmd('WinLeave', {
            buffer = M.buffer,
            callback = function()
                M.close_floating_window()
            end
        })
    end
end

function M.close_floating_window()
    close_buffer_if_not_edited(M.buffer)
    if M.window == nil then return end
    if vim.api.nvim_win_is_valid(M.window) then
        vim.api.nvim_win_close(M.window, true)
    end
end

return M
