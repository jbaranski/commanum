#!/usr/bin/env lua

-- Import formatWithCommas from commanum module
local commanum = require("commanum")
local formatWithCommas = commanum.formatWithCommas

local NUM_ITERATIONS = tonumber(os.getenv("NUM_ITERATIONS")) or 1000000
local MAX_U64 = 18446744073709551615  -- 2^64 - 1

-- High-resolution timer (uses os.clock for CPU time)
local function get_time_ns()
    return os.clock() * 1e9
end

-- Generate a random number string (Lua's math.random can't handle full u64 range directly)
-- We generate random digit strings to simulate the full range
local function random_u64_string()
    -- Random length between 1 and 20 digits (max u64 is 20 digits)
    local len = math.random(1, 20)
    local digits = {}

    -- First digit can't be 0 (unless it's the only digit)
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

-- Main performance test
local function main()
    print("Lua Performance Test")
    print("====================")
    print(string.format("Iterations: %d", NUM_ITERATIONS))
    print(string.format("Range: 0 to %s (max u64)\n", tostring(MAX_U64)))

    -- Seed random number generator
    math.randomseed(os.time())

    -- Pre-generate all random number strings
    print(string.format("Generating %d random numbers...", NUM_ITERATIONS))
    local gen_start = get_time_ns()

    local numbers = {}
    for i = 1, NUM_ITERATIONS do
        numbers[i] = random_u64_string()
    end

    local gen_end = get_time_ns()
    local gen_elapsed_ms = (gen_end - gen_start) / 1e6
    print(string.format("Generation time: %.3f ms\n", gen_elapsed_ms))

    print("Running formatting benchmark...")

    local bench_start = get_time_ns()

    for i = 1, NUM_ITERATIONS do
        formatWithCommas(numbers[i])
    end

    local bench_end = get_time_ns()
    local total_elapsed_ns = bench_end - bench_start

    -- Calculate statistics
    local total_ms = total_elapsed_ns / 1e6
    local avg_ns = total_elapsed_ns / NUM_ITERATIONS
    local ops_per_sec = NUM_ITERATIONS / (total_ms / 1000)

    -- Print results
    print("\nResults:")
    print("--------")
    print(string.format("Total benchmark time:  %.3f ms", total_ms))
    print(string.format("Average per operation: %.1f ns", avg_ns))
    print(string.format("Throughput: %.0f ops/sec", ops_per_sec))
end

main()
