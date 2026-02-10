const std = @import("std");
const commanum = @import("commanum");
const formatWithCommas = commanum.formatWithCommas;
const numberToWords = commanum.numberToWords;
const MAX_LEN = commanum.MAX_LEN;
const WORDS_MAX_LEN = commanum.WORDS_MAX_LEN;

const TimeUnit = enum {
    second,
    minute,
    hour,
    day,
};

const UnitOfTime = struct {
    multiplier: f64,
    unit: TimeUnit,

    fn toSeconds(self: UnitOfTime) f64 {
        const factor: f64 = switch (self.unit) {
            .second => 1.0,
            .minute => 60.0,
            .hour => 3600.0,
            .day => 86400.0,
        };
        return self.multiplier * factor;
    }
};

fn parseUnitOfTime(spec: []const u8) ?UnitOfTime {
    // Find where the numeric prefix ends and the unit name begins
    var split: usize = 0;
    for (spec, 0..) |c, i| {
        if (c >= '0' and c <= '9') {
            split = i + 1;
        } else {
            break;
        }
    }

    if (split == 0 or split == spec.len) return null;

    const num_str = spec[0..split];
    const unit_str = spec[split..];

    const multiplier = std.fmt.parseFloat(f64, num_str) catch return null;
    if (multiplier <= 0) return null;

    const unit: TimeUnit = if (eql(unit_str, "second") or eql(unit_str, "seconds") or eql(unit_str, "s"))
        .second
    else if (eql(unit_str, "minute") or eql(unit_str, "minutes") or eql(unit_str, "min"))
        .minute
    else if (eql(unit_str, "hour") or eql(unit_str, "hours") or eql(unit_str, "hr"))
        .hour
    else if (eql(unit_str, "day") or eql(unit_str, "days"))
        .day
    else
        return null;

    return .{ .multiplier = multiplier, .unit = unit };
}

fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

fn validateNumber(num_str: []const u8) bool {
    if (num_str.len == 0) return false;

    // If starts with '0', must be exactly "0" or "0.something"
    if (num_str[0] == '0' and num_str.len > 1) {
        if (num_str[1] != '.') return false;
    }

    return true;
}

fn formatValue(value: f64, buf: []u8) ![]const u8 {
    // Round to 2 decimal places
    const rounded = @round(value * 100.0) / 100.0;
    const int_part: u64 = @intFromFloat(@floor(rounded));
    const frac = rounded - @as(f64, @floatFromInt(int_part));

    // Convert integer part to string for commanum
    var int_str_buf: [24]u8 = undefined;
    const int_str = intToStr(int_part, &int_str_buf);

    // Format integer part with commas
    var comma_buf: [MAX_LEN]u8 = undefined;
    const comma_str = formatWithCommas(int_str, &comma_buf) catch return error.FormatError;

    var pos: usize = 0;
    @memcpy(buf[pos .. pos + comma_str.len], comma_str);
    pos += comma_str.len;

    // Append decimal part if non-zero
    const frac_rounded: u64 = @intFromFloat(@round(frac * 100.0));
    if (frac_rounded > 0) {
        buf[pos] = '.';
        pos += 1;
        buf[pos] = '0' + @as(u8, @intCast(frac_rounded / 10));
        pos += 1;
        const last_digit = @as(u8, @intCast(frac_rounded % 10));
        if (last_digit > 0) {
            buf[pos] = '0' + last_digit;
            pos += 1;
        }
    }

    return buf[0..pos];
}

fn intToStr(value: u64, buf: []u8) []const u8 {
    if (value == 0) {
        buf[0] = '0';
        return buf[0..1];
    }

    var v = value;
    var len: usize = 0;
    while (v > 0) {
        buf[len] = '0' + @as(u8, @intCast(v % 10));
        len += 1;
        v /= 10;
    }

    // Reverse
    var i: usize = 0;
    var j: usize = len - 1;
    while (i < j) {
        const tmp = buf[i];
        buf[i] = buf[j];
        buf[j] = tmp;
        i += 1;
        j -= 1;
    }

    return buf[0..len];
}

fn wordsForValue(value: f64, buf: []u8) ![]const u8 {
    const rounded = @round(value * 100.0) / 100.0;
    const int_part: u64 = @intFromFloat(@floor(rounded));

    var int_str_buf: [24]u8 = undefined;
    const int_str = intToStr(int_part, &int_str_buf);

    return numberToWords(int_str, buf) catch return error.WordsError;
}

const labels = [4][]const u8{ "per second", "per minute", "per hour", "per day" };
const multipliers = [4]f64{ 1.0, 60.0, 3600.0, 86400.0 };

fn printErr(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt, args);
}

pub fn main() !void {
    const args = std.os.argv;

    if (args.len < 2) {
        printErr("Error: Missing number argument.\nUsage: tps <number> [--uot <time_spec>]\n  Example: tps 1000000 --uot 1minute\n", .{});
        std.process.exit(1);
    }

    const num_str: []const u8 = std.mem.span(args[1]);

    // Validate leading zeros
    if (!validateNumber(num_str)) {
        printErr("Error: Leading zeros are not allowed (except for '0' or '0.x')\n", .{});
        std.process.exit(1);
    }

    // Parse the number as f64
    const count = std.fmt.parseFloat(f64, num_str) catch {
        printErr("Error: Invalid number '{s}'\n", .{num_str});
        std.process.exit(1);
    };

    if (count < 0) {
        printErr("Error: Number must be non-negative\n", .{});
        std.process.exit(1);
    }

    // Parse --uot argument (default: 1minute)
    var uot = UnitOfTime{ .multiplier = 1.0, .unit = .minute };

    var i: usize = 2;
    while (i < args.len) {
        const arg: []const u8 = std.mem.span(args[i]);
        if (eql(arg, "--uot")) {
            i += 1;
            if (i >= args.len) {
                printErr("Error: --uot requires a value (e.g., 1minute, 10second, 3hour, 1day)\n", .{});
                std.process.exit(1);
            }
            const uot_str: []const u8 = std.mem.span(args[i]);
            uot = parseUnitOfTime(uot_str) orelse {
                printErr("Error: Invalid unit of time '{s}'\n  Valid formats: 1second, 10minute, 3hour, 1day\n", .{uot_str});
                std.process.exit(1);
            };
        } else {
            printErr("Error: Unknown argument '{s}'\n", .{arg});
            std.process.exit(1);
        }
        i += 1;
    }

    const total_seconds = uot.toSeconds();
    const per_second = count / total_seconds;

    std.debug.print("\n", .{});

    for (multipliers, 0..) |mult, idx| {
        const value = per_second * mult;

        var fmt_buf: [64]u8 = undefined;
        const formatted = formatValue(value, &fmt_buf) catch {
            printErr("Error: Could not format result\n", .{});
            std.process.exit(1);
        };

        var words_buf: [WORDS_MAX_LEN]u8 = undefined;
        const words = wordsForValue(value, &words_buf) catch {
            printErr("Error: Could not convert to words\n", .{});
            std.process.exit(1);
        };

        // lowercase the first letter (commanum capitalizes it)
        var words_lower: [WORDS_MAX_LEN]u8 = undefined;
        @memcpy(words_lower[0..words.len], words);
        if (words.len > 0 and words_lower[0] >= 'A' and words_lower[0] <= 'Z') {
            words_lower[0] = words_lower[0] + 32;
        }
        const words_final = words_lower[0..words.len];

        std.debug.print("  {s}{s} : {s} ({s})\n", .{
            labels[idx],
            padSpaces(10 - labels[idx].len),
            formatted,
            words_final,
        });
    }

    std.debug.print("\n", .{});
}

fn padSpaces(count: usize) []const u8 {
    const spaces = "          ";
    if (count > spaces.len) return spaces;
    return spaces[0..count];
}
