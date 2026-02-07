const std = @import("std");
const commanum = @import("commanum");
const formatWithCommas = commanum.formatWithCommas;
const numberToWords = commanum.numberToWords;
const MAX_LEN = commanum.MAX_LEN;
const WORDS_MAX_LEN = commanum.WORDS_MAX_LEN;

const DEFAULT_NUM_ITERATIONS = 1_000_000;

fn getNumIterations() usize {
    const val = std.posix.getenv("NUM_ITERATIONS") orelse return DEFAULT_NUM_ITERATIONS;
    return std.fmt.parseInt(usize, val, 10) catch DEFAULT_NUM_ITERATIONS;
}

pub fn main() !void {
    const NUM_ITERATIONS = getNumIterations();
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

    const allocator = std.heap.page_allocator;

    // Pre-generate all random number strings
    std.debug.print("Generating {d} random number strings...\n", .{NUM_ITERATIONS});
    var gen_timer = try std.time.Timer.start();

    const num_strs = try allocator.alloc([20]u8, NUM_ITERATIONS);
    defer allocator.free(num_strs);
    const num_lens = try allocator.alloc(u8, NUM_ITERATIONS);
    defer allocator.free(num_lens);

    for (num_strs, num_lens) |*str_buf, *len| {
        const s = std.fmt.bufPrint(str_buf, "{d}", .{random.int(u64)}) catch unreachable;
        len.* = @intCast(s.len);
    }

    const gen_elapsed_ns = gen_timer.read();
    std.debug.print("Generation time: {d:.3} ms\n\n", .{@as(f64, @floatFromInt(gen_elapsed_ns)) / 1_000_000.0});

    var format_buf: [MAX_LEN]u8 = undefined;

    std.debug.print("Running formatting benchmark...\n", .{});

    var bench_timer = try std.time.Timer.start();

    for (num_strs, num_lens) |*str_buf, len| {
        const result = formatWithCommas(str_buf[0..len], &format_buf) catch "";
        std.mem.doNotOptimizeAway(result.ptr);
    }

    const total_elapsed_ns = bench_timer.read();

    // Calculate statistics
    const total_ms: f64 = @as(f64, @floatFromInt(total_elapsed_ns)) / 1_000_000.0;
    const avg_ns: f64 = @as(f64, @floatFromInt(total_elapsed_ns)) / @as(f64, @floatFromInt(NUM_ITERATIONS));
    const ops_per_sec: f64 = @as(f64, @floatFromInt(NUM_ITERATIONS)) / (total_ms / 1000.0);

    // Print results
    std.debug.print("\nformatWithCommas Results:\n", .{});
    std.debug.print("------------------------\n", .{});
    std.debug.print("Total benchmark time:  {d:.3} ms\n", .{total_ms});
    std.debug.print("Average per operation: {d:.1} ns\n", .{avg_ns});
    std.debug.print("Throughput: {d:.0} ops/sec\n", .{ops_per_sec});

    // numberToWords benchmark
    var words_buf: [WORDS_MAX_LEN]u8 = undefined;

    std.debug.print("\nRunning numberToWords benchmark...\n", .{});

    var words_timer = try std.time.Timer.start();

    for (num_strs, num_lens) |*str_buf, len| {
        _ = numberToWords(str_buf[0..len], &words_buf) catch {};
    }

    const words_elapsed_ns = words_timer.read();

    const words_ms: f64 = @as(f64, @floatFromInt(words_elapsed_ns)) / 1_000_000.0;
    const words_avg_ns: f64 = @as(f64, @floatFromInt(words_elapsed_ns)) / @as(f64, @floatFromInt(NUM_ITERATIONS));
    const words_ops: f64 = @as(f64, @floatFromInt(NUM_ITERATIONS)) / (words_ms / 1000.0);

    std.debug.print("\nnumberToWords Results:\n", .{});
    std.debug.print("---------------------\n", .{});
    std.debug.print("Total benchmark time:  {d:.3} ms\n", .{words_ms});
    std.debug.print("Average per operation: {d:.1} ns\n", .{words_avg_ns});
    std.debug.print("Throughput: {d:.0} ops/sec\n", .{words_ops});
}
