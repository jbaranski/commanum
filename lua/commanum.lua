#!/usr/bin/env lua

local unpack = table.unpack or unpack  -- Lua 5.2+ compatibility
local table_new = require("table.new")

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
    local result = table_new(final_len, 0)
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

-- Convert a numeric string to English words
function M.numberToWords(num_str)
    -- Strip leading zeros but keep at least one digit
    local stripped = num_str:match("^0*(%d+)$")
    if not stripped or stripped == "" then
        stripped = "0"
    end

    if stripped == "0" then
        return "Zero"
    end

    local ones = {
        [0] = "", "one", "two", "three", "four", "five",
        "six", "seven", "eight", "nine", "ten",
        "eleven", "twelve", "thirteen", "fourteen", "fifteen",
        "sixteen", "seventeen", "eighteen", "nineteen",
    }

    local tens = {
        [0] = "", "", "twenty", "thirty", "forty", "fifty",
        "sixty", "seventy", "eighty", "ninety",
    }

    local scales = {
        [0] = "", "thousand", "million", "billion", "trillion",
        "quadrillion", "quintillion", "sextillion",
    }

    -- Convert a 1-3 digit number (0-999) to words
    local function group_to_words(n)
        if n == 0 then return "" end

        local parts = {}
        if n >= 100 then
            parts[#parts + 1] = ones[math.floor(n / 100)] .. " hundred"
            n = n % 100
            if n > 0 then
                parts[#parts + 1] = "and"
            end
        end

        if n >= 20 then
            local t = tens[math.floor(n / 10)]
            local o = n % 10
            if o > 0 then
                parts[#parts + 1] = t .. "-" .. ones[o]
            else
                parts[#parts + 1] = t
            end
        elseif n > 0 then
            parts[#parts + 1] = ones[n]
        end

        return table.concat(parts, " ")
    end

    -- Split the number string into groups of 3 from the right
    local groups = {}
    local len = #stripped
    local i = len
    while i > 0 do
        local start = math.max(1, i - 2)
        local group_str = stripped:sub(start, i)
        groups[#groups + 1] = tonumber(group_str)
        i = start - 1
    end

    -- Build words from highest group to lowest
    local parts = {}
    local num_groups = #groups
    for g = num_groups, 1, -1 do
        local val = groups[g]
        if val > 0 then
            local scale_idx = g - 1
            local words = group_to_words(val)
            if scales[scale_idx] ~= "" then
                words = words .. " " .. scales[scale_idx]
            end
            parts[#parts + 1] = words
        end
    end

    -- Insert "and" before the last group if it's < 100 and there are higher groups
    -- but only if the last group doesn't already contain "and"
    if #parts > 1 and groups[1] > 0 and groups[1] < 100 then
        local last = parts[#parts]
        parts[#parts] = "and " .. last
    end

    local result = table.concat(parts, " ")

    -- Capitalize first letter
    return result:sub(1, 1):upper() .. result:sub(2)
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

    local input = arg[1]
    local formatted, err = M.formatWithCommas(input)

    if not formatted then
        io.stderr:write("Error: Please provide only digits\n")
        os.exit(1)
    end

    local words = M.numberToWords(input)

    print("")
    print("  Digits : " .. input)
    print("  Commas : " .. formatted)
    print("   Words : " .. words)
    print("")
end

return M
