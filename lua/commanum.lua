#!/usr/bin/env lua

local unpack = table.unpack or unpack  -- Lua 5.2+ compatibility

local M = {}

local MAX_LEN = 64

-- Format a numeric string with commas every 3 digits from the right
function M.formatWithCommas(num_str)
    local num_len = #num_str
    local num_comma = math.floor((num_len - 1) / 3)
    local final_len = num_len + num_comma

    -- TODO: remove this check and ensure this can never happen with validation/tests
    if final_len > MAX_LEN then
        return nil, "BufferTooSmall"
    end

    -- Validate that all characters are digits (byte loop is faster than pattern matching)
    -- TODO: support float
    for i = 1, num_len do
        local b = num_str:byte(i)
        if b < 48 or b > 57 then  -- '0' = 48, '9' = 57
            return nil, "InvalidInput"
        end
    end

    -- Build the formatted string from right to left using pre-sized array of bytes
    local result = {}
    local str_idx = num_len
    local dest_idx = final_len
    local digit_count = 0

    while str_idx > 0 do
        if digit_count == 3 then
            result[dest_idx] = 44  -- ',' = 44
            dest_idx = dest_idx - 1
            digit_count = 0
        end

        result[dest_idx] = num_str:byte(str_idx)
        dest_idx = dest_idx - 1
        str_idx = str_idx - 1
        digit_count = digit_count + 1
    end

    return string.char(unpack(result))
end

-- Run as CLI if executed directly (not required as module)
if arg and arg[0] and arg[0]:match("commanum%.lua$") then
    if #arg < 1 then
        io.stderr:write("Error: Missing argument.\n")
        os.exit(1)
    end
    if #arg > 1 then
        io.stderr:write("Error: Too many arguments.\n")
        os.exit(1)
    end

    local formatted, err = M.formatWithCommas(arg[1])

    if not formatted then
        io.stderr:write("Error: Please provide only digits\n")
        os.exit(1)
    end

    -- TODO: support some kind of flag(s) that allow more verbose output
    print(formatted)
end

return M
