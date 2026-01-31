const std = @import("std");
const commanum = @import("commanum");
const formatWithCommas = commanum.formatWithCommas;
const MAX_LEN = commanum.MAX_LEN;

const NUM_ITERATIONS = 1_000_000;

pub fn main() !void {
    std.debug.print("Zig Performance Test\n", .{});
    std.debug.print("====================\n", .{});
    std.debug.print("Iterations: {d}\n", .{NUM_ITERATIONS});
    std.debug.print("Range: 0 to {d} (max u64)\n\n", .{std.math.maxInt(u64)});

    // Initialize random number generator
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();

    // Pre-generate all random numbers to measure formatting time only
    std.debug.print("Generating {d} random numbers...\n", .{NUM_ITERATIONS});
    const gen_start = std.time.nanoTimestamp();

    var numbers: [NUM_ITERATIONS]u64 = undefined;
    for (&numbers) |*n| {
        n.* = random.int(u64);
    }

    const gen_end = std.time.nanoTimestamp();
    const gen_elapsed_ns: u64 = @intCast(gen_end - gen_start);
    std.debug.print("Generation time: {d:.3} ms\n\n", .{@as(f64, @floatFromInt(gen_elapsed_ns)) / 1_000_000.0});

    // Buffers for conversion
    var num_str_buf: [20]u8 = undefined; // max u64 is 20 digits
    var format_buf: [MAX_LEN]u8 = undefined;

    std.debug.print("Running formatting benchmark...\n", .{});

    const bench_start = std.time.nanoTimestamp();

    for (numbers) |num| {
        const num_str = std.fmt.bufPrint(&num_str_buf, "{d}", .{num}) catch continue;
        _ = formatWithCommas(num_str, &format_buf) catch {};
    }

    const bench_end = std.time.nanoTimestamp();
    const total_elapsed_ns: u64 = @intCast(bench_end - bench_start);

    // Calculate statistics
    const total_ms: f64 = @as(f64, @floatFromInt(total_elapsed_ns)) / 1_000_000.0;
    const avg_ns: f64 = @as(f64, @floatFromInt(total_elapsed_ns)) / @as(f64, @floatFromInt(NUM_ITERATIONS));
    const ops_per_sec: f64 = @as(f64, @floatFromInt(NUM_ITERATIONS)) / (total_ms / 1000.0);

    // Print results
    std.debug.print("\nResults:\n", .{});
    std.debug.print("--------\n", .{});
    std.debug.print("Total benchmark time:  {d:.3} ms\n", .{total_ms});
    std.debug.print("Average per operation: {d:.1} ns\n", .{avg_ns});
    std.debug.print("Throughput: {d:.0} ops/sec\n", .{ops_per_sec});
}
