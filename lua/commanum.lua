#!/usr/bin/env lua

local MAX_LEN = 64

-- Format a numeric string with commas every 3 digits from the right
local function formatWithCommas(num_str)
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

    -- Build the formatted string from right to left
    local result = {}
    local digit_count = 0

    for i = num_len, 1, -1 do
        if digit_count == 3 then
            table.insert(result, 1, ",")
            digit_count = 0
        end

        table.insert(result, 1, num_str:sub(i, i))
        digit_count = digit_count + 1
    end

    return table.concat(result)
end

-- Main
local function main()
    if #arg < 1 then
        io.stderr:write("Error: Missing argument.\n")
        return
    end
    if #arg > 1 then
        io.stderr:write("Error: Too many arguments.\n")
        return
    end

    local num_str = arg[1]
    local formatted, err = formatWithCommas(num_str)

    if not formatted then
        io.stderr:write("Error: Please provide only digits\n")
        os.exit(1)
    end

    -- TODO: support some kind of flag(s) that allow more verbose output
    print(formatted)
end

main()
