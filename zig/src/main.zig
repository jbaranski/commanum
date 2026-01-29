const std = @import("std");
const commanum = @import("commanum");
const formatWithCommas = commanum.formatWithCommas;
const MAX_LEN = commanum.MAX_LEN;

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
    var buffer: [MAX_LEN]u8 = undefined;
    const formatted_slice = formatWithCommas(num_str, &buffer) catch {
        std.debug.print("Error: Please provide only digits\n", .{});
        std.process.exit(1);
    };

    // TODO: support some kind of flag(s) that allow more verbose output
    std.debug.print("{s}\n", .{formatted_slice});
}
