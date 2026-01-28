const std = @import("std");
const time = std.time;

// Import formatWithCommas from commanum module
const commanum = @import("commanum");
const formatWithCommas = commanum.formatWithCommas;
const MAX_LEN = commanum.MAX_LEN;

const NUM_ITERATIONS = 1_000_000;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Zig Performance Test\n", .{});
    try stdout.print("====================\n", .{});
    try stdout.print("Iterations: {d}\n", .{NUM_ITERATIONS});
    try stdout.print("Range: 0 to {d} (max u64)\n\n", .{std.math.maxInt(u64)});

    // Initialize random number generator
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();

    // Pre-generate all random numbers to measure formatting time only
    try stdout.print("Generating {d} random numbers...\n", .{NUM_ITERATIONS});
    const gen_start = time.nanoTimestamp();

    var numbers: [NUM_ITERATIONS]u64 = undefined;
    for (&numbers) |*n| {
        n.* = random.int(u64);
    }

    const gen_end = time.nanoTimestamp();
    const gen_elapsed_ns: u64 = @intCast(gen_end - gen_start);
    try stdout.print("Generation time: {d:.3} ms\n\n", .{@as(f64, @floatFromInt(gen_elapsed_ns)) / 1_000_000.0});

    // Buffers for conversion
    var num_str_buf: [20]u8 = undefined; // max u64 is 20 digits
    var format_buf: [MAX_LEN]u8 = undefined;

    // Timing variables
    var total_format_ns: u64 = 0;
    var min_ns: u64 = std.math.maxInt(u64);
    var max_ns: u64 = 0;
    var successful: u64 = 0;

    try stdout.print("Running formatting benchmark...\n", .{});

    const bench_start = time.nanoTimestamp();

    for (numbers) |num| {
        // Convert number to string
        const num_str = std.fmt.bufPrint(&num_str_buf, "{d}", .{num}) catch continue;

        // Time the formatWithCommas call
        const start = time.nanoTimestamp();
        const result = formatWithCommas(num_str, &format_buf);
        const end = time.nanoTimestamp();

        const elapsed: u64 = @intCast(end - start);
        total_format_ns += elapsed;

        if (result) |_| {
            successful += 1;
            if (elapsed < min_ns) min_ns = elapsed;
            if (elapsed > max_ns) max_ns = elapsed;
        } else |_| {}
    }

    const bench_end = time.nanoTimestamp();
    const total_elapsed_ns: u64 = @intCast(bench_end - bench_start);

    // Calculate statistics
    const avg_ns: f64 = @as(f64, @floatFromInt(total_format_ns)) / @as(f64, @floatFromInt(successful));
    const total_ms: f64 = @as(f64, @floatFromInt(total_elapsed_ns)) / 1_000_000.0;
    const format_only_ms: f64 = @as(f64, @floatFromInt(total_format_ns)) / 1_000_000.0;
    const ops_per_sec: f64 = @as(f64, @floatFromInt(successful)) / (total_ms / 1000.0);

    // Print results
    try stdout.print("\nResults:\n", .{});
    try stdout.print("--------\n", .{});
    try stdout.print("Successful operations: {d} / {d}\n", .{ successful, NUM_ITERATIONS });
    try stdout.print("Total benchmark time:  {d:.3} ms\n", .{total_ms});
    try stdout.print("Format-only time:      {d:.3} ms\n", .{format_only_ms});
    try stdout.print("\nPer-operation statistics:\n", .{});
    try stdout.print("  Average: {d:.1} ns\n", .{avg_ns});
    try stdout.print("  Min:     {d} ns\n", .{min_ns});
    try stdout.print("  Max:     {d} ns\n", .{max_ns});
    try stdout.print("\nThroughput: {d:.0} ops/sec\n", .{ops_per_sec});
}
