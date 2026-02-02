const std = @import("std");
const commanum = @import("commanum");
const formatWithCommas = commanum.formatWithCommas;
const numberToWords = commanum.numberToWords;
const MAX_LEN = commanum.MAX_LEN;
const WORDS_MAX_LEN = commanum.WORDS_MAX_LEN;

pub fn main() !void {
    if (std.os.argv.len < 2) {
        std.debug.print("Error: Missing argument.\n", .{});
        return;
    }
    if (std.os.argv.len > 2) {
        std.debug.print("Error: Too many arguments.\n", .{});
        return;
    }

    const num_str: []const u8 = std.mem.span(std.os.argv[1]);

    var comma_buf: [MAX_LEN]u8 = undefined;
    const formatted = formatWithCommas(num_str, &comma_buf) catch {
        std.debug.print("Error: Please provide only digits\n", .{});
        std.process.exit(1);
    };

    var words_buf: [WORDS_MAX_LEN]u8 = undefined;
    const words = numberToWords(num_str, &words_buf) catch {
        std.debug.print("Error: Could not convert to words\n", .{});
        std.process.exit(1);
    };

    std.debug.print("\n  Digits : {s}\n  Commas : {s}\n   Words : {s}\n\n", .{ num_str, formatted, words });
}
