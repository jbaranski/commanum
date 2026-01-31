#!/usr/bin/env lua
--[[
Memory profiler test using Tarantool's LuaJIT misc.memprof
Requires: Tarantool's LuaJIT fork (https://github.com/tarantool/luajit)
Run with: make perf-lua-memprof (local, requires Tarantool LuaJIT)
          make docker-perf-valgrind (Docker, automatically uses Tarantool LuaJIT)
]]

-- Import formatWithCommas from commanum module
local commanum = require("commanum")
local formatWithCommas = commanum.formatWithCommas

local NUM_ITERATIONS = tonumber(os.getenv("NUM_ITERATIONS")) or 1000000
local MAX_U64 = 18446744073709551615  -- 2^64 - 1
local MEMPROF_OUTPUT = os.getenv("MEMPROF_OUTPUT") or "memprof.bin"

-- Check for misc.memprof availability
if type(misc) ~= "table" or type(misc.memprof) ~= "table" then
    io.stderr:write("Error: misc.memprof not available.\n")
    io.stderr:write("This test requires Tarantool's LuaJIT fork.\n")
    io.stderr:write("Build from: https://github.com/tarantool/luajit (branch: tarantool)\n")
    os.exit(1)
end

-- Generate a random number string
local function random_u64_string()
    local len = math.random(1, 20)
    local digits = {}
    if len == 1 then
        digits[1] = tostring(math.random(0, 9))
    else
        digits[1] = tostring(math.random(1, 9))
        for i = 2, len do
            digits[i] = tostring(math.random(0, 9))
        end
    end
    return table.concat(digits)
end

local function main()
    print("Lua Performance Test (misc.memprof)")
    print("=====================================")
    print(string.format("Iterations: %d", NUM_ITERATIONS))
    print(string.format("Range: 0 to %s (max u64)", tostring(MAX_U64)))
    print(string.format("Output: %s\n", MEMPROF_OUTPUT))

    math.randomseed(os.time())

    -- Pre-generate random numbers (outside profiling window)
    print(string.format("Generating %d random numbers...", NUM_ITERATIONS))
    local numbers = {}
    for i = 1, NUM_ITERATIONS do
        numbers[i] = random_u64_string()
    end
    print("Generation complete.\n")

    -- Start memory profiler
    print("Starting memory profiler...")
    local started, err = misc.memprof.start(MEMPROF_OUTPUT)
    if not started then
        io.stderr:write(string.format("Error starting memprof: %s\n", tostring(err)))
        os.exit(1)
    end

    -- Run benchmark under profiling
    local bench_start = os.clock()

    for i = 1, NUM_ITERATIONS do
        formatWithCommas(numbers[i])
    end

    local bench_end = os.clock()

    -- Collect garbage before stopping to capture all dead objects
    collectgarbage()

    -- Stop memory profiler
    local stopped, stop_err = misc.memprof.stop()
    if not stopped then
        io.stderr:write(string.format("Error stopping memprof: %s\n", tostring(stop_err)))
        os.exit(1)
    end

    -- Calculate and print results
    local total_ms = (bench_end - bench_start) * 1000
    local avg_ns = (total_ms * 1e6) / NUM_ITERATIONS
    local ops_per_sec = NUM_ITERATIONS / (total_ms / 1000)

    print("\nResults:")
    print("--------")
    print(string.format("Total benchmark time:  %.3f ms", total_ms))
    print(string.format("Average per operation: %.1f ns", avg_ns))
    print(string.format("Throughput: %.0f ops/sec", ops_per_sec))
    print(string.format("\nMemory profile written to: %s", MEMPROF_OUTPUT))
    print("Parse with: luajit -tm " .. MEMPROF_OUTPUT)
end

main()
