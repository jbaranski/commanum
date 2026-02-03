#!/usr/bin/env lua
--[[
Memory allocation profiler using debug.sethook + collectgarbage("count").
Works with any standard LuaJIT (including OpenResty's fork).

Hooks every line, measures memory delta, and attributes allocations to
source locations. JIT is disabled during profiling (debug hooks force
interpreter mode) but allocation hotspots are the same.

Run with: make perf-lua-memprof
Configure: MEMPROF_ITERATIONS=50000 make perf-lua-memprof
]]

local commanum = require("commanum")
local formatWithCommas = commanum.formatWithCommas
local numberToWords = commanum.numberToWords

local NUM_ITERATIONS = tonumber(os.getenv("MEMPROF_ITERATIONS") or os.getenv("NUM_ITERATIONS")) or 1000000

-- Profiling state
local alloc_by_location = {}
local prev_mem = 0
local prev_src = ""
local prev_line = 0
local profiler_src = nil

local function mem_hook(event, line)
    local mem = collectgarbage("count")
    local delta = mem - prev_mem

    local info = debug.getinfo(2, "Sl")
    local src = info.short_src or "?"
    local cur_line = info.currentline or 0

    -- Attribute positive deltas to the PREVIOUS line (which caused the allocation)
    -- Skip allocations from this profiler file itself
    if delta > 0 and prev_line > 0 and prev_src ~= profiler_src then
        local key = prev_src .. ":" .. prev_line
        local entry = alloc_by_location[key]
        if entry then
            entry.kb = entry.kb + delta
            entry.count = entry.count + 1
        else
            alloc_by_location[key] = { kb = delta, count = 1, src = prev_src, line = prev_line }
        end
    end

    -- Re-measure AFTER our own allocations so they are excluded from the next delta
    prev_mem = collectgarbage("count")
    prev_src = src
    prev_line = cur_line
end

-- Source line reader for the report
local source_cache = {}
local function get_source_line(file, line_num)
    if not source_cache[file] then
        local lines = {}
        local f = io.open(file, "r")
        if f then
            for l in f:lines() do
                lines[#lines + 1] = l
            end
            f:close()
        end
        source_cache[file] = lines
    end
    local line = source_cache[file][line_num]
    return line and line:match("^%s*(.-)%s*$") or ""
end

local function main()
    -- Identify our own source file to filter from results
    local my_info = debug.getinfo(1, "S")
    profiler_src = my_info.short_src

    print("Lua Memory Profile (debug.sethook + collectgarbage)")
    print("====================================================")
    print(string.format("Iterations: %d", NUM_ITERATIONS))
    print("Note: JIT disabled during profiling (debug hooks force interpreter mode)")
    print("")

    math.randomseed(os.time())

    -- Pre-generate random numbers outside profiling window
    print(string.format("Generating %d random numbers...", NUM_ITERATIONS))
    local numbers = {}
    for i = 1, NUM_ITERATIONS do
        local len = math.random(1, 20)
        local digits = {}
        if len == 1 then
            digits[1] = tostring(math.random(0, 9))
        else
            digits[1] = tostring(math.random(1, 9))
            for j = 2, len do
                digits[j] = tostring(math.random(0, 9))
            end
        end
        numbers[i] = table.concat(digits)
    end
    print("Generation complete.\n")

    -- Force full GC before profiling
    collectgarbage("collect")
    collectgarbage("collect")

    print("Running profiled benchmark...")

    -- Start profiling
    prev_mem = collectgarbage("count")
    prev_src = ""
    prev_line = 0

    debug.sethook(mem_hook, "l")

    for i = 1, NUM_ITERATIONS do
        formatWithCommas(numbers[i])
    end

    debug.sethook()

    print("Profile complete.\n")

    -- Sort by total KB allocated
    local sorted = {}
    local total_kb = 0
    local total_allocs = 0
    for key, data in pairs(alloc_by_location) do
        sorted[#sorted + 1] = data
        data.key = key
        total_kb = total_kb + data.kb
        total_allocs = total_allocs + data.count
    end
    table.sort(sorted, function(a, b) return a.kb > b.kb end)

    -- Print report
    print("Top Allocation Sites:")
    print("---------------------")
    print(string.format("%-30s %10s %8s  %s", "LOCATION", "KB", "COUNT", "CODE"))
    print(string.rep("-", 90))

    local shown = math.min(20, #sorted)
    for i = 1, shown do
        local entry = sorted[i]
        local code = get_source_line(entry.src, entry.line)
        if #code > 38 then code = code:sub(1, 35) .. "..." end
        print(string.format("%-30s %10.1f %8d  %s",
            entry.key, entry.kb, entry.count, code))
    end

    print("")
    print("Summary:")
    print("--------")
    print(string.format("Total tracked allocations: %d", total_allocs))
    print(string.format("Total tracked memory: %.1f KB", total_kb))
    if NUM_ITERATIONS > 0 then
        print(string.format("Average per formatWithCommas call: ~%.1f bytes",
            (total_kb * 1024) / NUM_ITERATIONS))
    end

    -- Profile numberToWords
    print("\n\nnumberToWords Memory Profile")
    print("============================")

    -- Reset profiling state
    alloc_by_location = {}

    collectgarbage("collect")
    collectgarbage("collect")

    print("Running profiled numberToWords benchmark...")

    prev_mem = collectgarbage("count")
    prev_src = ""
    prev_line = 0

    debug.sethook(mem_hook, "l")

    for i = 1, NUM_ITERATIONS do
        numberToWords(numbers[i])
    end

    debug.sethook()

    print("Profile complete.\n")

    local words_sorted = {}
    local words_total_kb = 0
    local words_total_allocs = 0
    for key, data in pairs(alloc_by_location) do
        words_sorted[#words_sorted + 1] = data
        data.key = key
        words_total_kb = words_total_kb + data.kb
        words_total_allocs = words_total_allocs + data.count
    end
    table.sort(words_sorted, function(a, b) return a.kb > b.kb end)

    print("Top Allocation Sites:")
    print("---------------------")
    print(string.format("%-30s %10s %8s  %s", "LOCATION", "KB", "COUNT", "CODE"))
    print(string.rep("-", 90))

    local words_shown = math.min(20, #words_sorted)
    for i = 1, words_shown do
        local entry = words_sorted[i]
        local code = get_source_line(entry.src, entry.line)
        if #code > 38 then code = code:sub(1, 35) .. "..." end
        print(string.format("%-30s %10.1f %8d  %s",
            entry.key, entry.kb, entry.count, code))
    end

    print("")
    print("Summary:")
    print("--------")
    print(string.format("Total tracked allocations: %d", words_total_allocs))
    print(string.format("Total tracked memory: %.1f KB", words_total_kb))
    if NUM_ITERATIONS > 0 then
        print(string.format("Average per numberToWords call: ~%.1f bytes",
            (words_total_kb * 1024) / NUM_ITERATIONS))
    end
end

main()
