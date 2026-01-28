#!/usr/bin/env lua
--[[
Memory-tracking performance test using collectgarbage("count")
Run with: make perf-lua-mem
]]

-- Import formatWithCommas from commanum module
local commanum = require("commanum")
local formatWithCommas = commanum.formatWithCommas

local NUM_ITERATIONS = 1000000
local MAX_U64 = 18446744073709551615  -- 2^64 - 1

-- Helper to get memory in KB
local function get_mem_kb()
    collectgarbage("collect")  -- Force GC for accurate reading
    return collectgarbage("count")
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

-- Main performance test with memory tracking
local function main()
    print("Lua Performance Test (Memory Tracking)")
    print("=======================================")
    print(string.format("Iterations: %d", NUM_ITERATIONS))
    print(string.format("Range: 0 to %s (max u64)\n", tostring(MAX_U64)))

    -- Seed random number generator
    math.randomseed(os.time())

    -- Initial memory
    local mem_start = get_mem_kb()
    print(string.format("Initial memory: %.2f KB", mem_start))

    -- Pre-generate all random number strings
    print(string.format("\nGenerating %d random numbers...", NUM_ITERATIONS))
    local numbers = {}
    for i = 1, NUM_ITERATIONS do
        numbers[i] = random_u64_string()
    end

    local mem_after_gen = get_mem_kb()
    print(string.format("Memory after generation: %.2f KB", mem_after_gen))
    print(string.format("Memory used for numbers: %.2f KB", mem_after_gen - mem_start))

    -- Track memory during benchmark
    local mem_before_bench = get_mem_kb()
    local mem_peak = mem_before_bench
    local mem_samples = {}
    local sample_interval = NUM_ITERATIONS / 10  -- Sample 10 times during run

    print("\nRunning formatting benchmark with memory tracking...")

    local successful = 0
    local bench_start = os.clock()

    for i = 1, NUM_ITERATIONS do
        local num_str = numbers[i]
        local result, err = formatWithCommas(num_str)

        if result then
            successful = successful + 1
        end

        -- Sample memory periodically (without forcing GC for speed)
        if i % sample_interval == 0 then
            local current_mem = collectgarbage("count")
            if current_mem > mem_peak then
                mem_peak = current_mem
            end
            table.insert(mem_samples, {iteration = i, mem_kb = current_mem})
        end
    end

    local bench_end = os.clock()
    local bench_time_ms = (bench_end - bench_start) * 1000

    -- Force GC and get final memory
    local mem_after_bench = get_mem_kb()

    -- Print results
    print("\nResults:")
    print("--------")
    print(string.format("Successful operations: %d / %d", successful, NUM_ITERATIONS))
    print(string.format("Total benchmark time:  %.3f ms", bench_time_ms))
    print(string.format("Throughput: %.0f ops/sec", successful / (bench_time_ms / 1000)))

    print("\nMemory Statistics:")
    print("------------------")
    print(string.format("Before benchmark:  %.2f KB", mem_before_bench))
    print(string.format("Peak during run:   %.2f KB", mem_peak))
    print(string.format("After benchmark:   %.2f KB", mem_after_bench))
    print(string.format("Memory delta:      %.2f KB", mem_after_bench - mem_before_bench))
    print(string.format("Peak increase:     %.2f KB", mem_peak - mem_before_bench))

    print("\nMemory Samples During Run:")
    print("--------------------------")
    for _, sample in ipairs(mem_samples) do
        local pct = (sample.iteration / NUM_ITERATIONS) * 100
        print(string.format("  %3.0f%% (%7d): %.2f KB", pct, sample.iteration, sample.mem_kb))
    end

    -- GC stats
    print("\nGarbage Collection Info:")
    print("------------------------")
    collectgarbage("collect")
    local final_mem = collectgarbage("count")
    print(string.format("After full GC: %.2f KB", final_mem))
    print(string.format("Freed by GC:   %.2f KB", mem_after_bench - final_mem))
end

main()
