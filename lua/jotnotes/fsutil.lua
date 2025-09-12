local M = {}

--- Function to normalize a path and ensure it ends with a delimiter if it's a directory
---@param path string path to normalize
---@return string normalized path
function M.normalize_path(path)
    local real_path = vim.loop.fs_realpath(path)
    if not real_path then
        -- Fallback to expanding the path if fs_realpath fails
        real_path = vim.fn.fnamemodify(path, ":p")
    end
    -- Check if the path is a directory
    local is_dir = vim.loop.fs_stat(real_path) and vim.loop.fs_stat(real_path).type == "directory"
    -- Append the path separator if it's a directory and not already present
    if is_dir and not real_path:match(vim.pesc(vim.loop.os_uname().sysname == "Windows" and "\\" or "/") .. "$") then
        real_path = real_path .. (vim.loop.os_uname().sysname == "Windows" and "\\" or "/")
    end
    return real_path
end

--- Function to expand environment variables in a expression
---@param expresison string containing a environment variable to be substituted
---@return string substituted string
function M.expand_env_var(expression)
    return expression:gsub("%$(%w+)", function(var)
        return os.getenv(var) or "$" .. var
    end)
end

--- Check if file exists
---@param path string path to check
---@return nil if exists
function M.file_exists(path)
    local uv = vim.loop
    local stat = uv.fs_stat(path)
    return stat and stat.type == 'file'
end

--- Check if directory exists
---@param path string path to check
---@return nil if it exists
function M.directory_exists(path)
    local uv = vim.loop
    local stat = uv.fs_stat(path)
    return stat and stat.type == 'directory'
end

--- Function to create a directory
---@param path string directory to create
function M.create_directory(path)
    local uv = vim.loop
    uv.fs_mkdir(path, 511) -- 511 is the octal representation of 0777
end

--- Function to create the given directory if it does not exists
---@param path string directory to create if it doesn't exist
---@return boolean directory existed
function M.ensure_directory_exists(path)
    local dir_path = path

    if not M.directory_exists(dir_path) then
        M.create_directory(dir_path)
        return false
    else
        return true
    end
end

--- Function to create file and write some text to it
---@param file_path string path to the file to be created
---@param text string text to write to file
function M.create_file_with_text(file_path, text)
    local uv = vim.loop

    local fd = uv.fs_open(file_path, "w", 438) -- 438 is the octal for 0666 permissions
    -- Check if the file descriptor is valid
    if fd then
        -- Write text to the file
        uv.fs_write(fd, text, -1)
        vim.loop.fs_close(fd)
    end
end

--- Copy a file from one path to another
---@param path1 string from location
---@param path2 string to location
function M.copy_file(from_path, to_path)
    local uv = vim.uv or vim.loop

    vim.fn.mkdir(vim.fn.fnamemodify(to_path, ":h"), "p")

    -- Copy (synchronous). Returns true on success, or nil + error message.
    local ok, err = uv.fs_copyfile(from_path, to_path)
    if not ok then
        vim.notify("[JotNotes] | File copy failed from "..from_path.." to "..to_path, vim.log.levels.ERROR)
    end
end

--- Returns filename (everything after the last path delimiter)
---@param path string path to exctract filename from
---@return string extracted filename
local function get_filename_from_path(path)
    -- Match the last segment after the final slash or backslash
    return path:match("^.+[\\/](.+)$") or path
end

--- Check if a file path has a certain extension
---@param path string file path
---@param extension string extension type
---@return boolean match result
function M.match_file_extension(path, extension)
    return path:match("%." .. extension .. "$") ~= nil
end

function M.file_completion(cwd)
    local working_directory = cwd
    local function completion(arg_lead, cmd_line, cursor_pos)
        local notes_dir = vim.fn.expand(working_directory .. arg_lead) -- Directory to search for files
        local files = vim.fn.readdir(notes_dir)                        -- List files in the directory
        local matches = {}
        for _, file in ipairs(files) do
            table.insert(matches, file)
        end
        return matches
    end
    return completion
end

function M.generate_timestamp(format)
    if format == nil then
        format = "%Y%m%d%H%M%S"
    end
    -- Get the current date and time
    local timestamp = os.date(format)
    return timestamp
end

return M
