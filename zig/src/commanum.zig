pub const MAX_LEN = 64;

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

pub fn formatWithCommas(
    num_str: []const u8,
    buffer: []u8,
) ![]const u8 {
    const num_len: u8 = @intCast(num_str.len);
    const num_comma: u8 = (num_len - 1) / 3;
    const final_len: u8 = num_len + num_comma;

    // TODO: remove this check and ensure this can never happen with validation/tests
    if (final_len > buffer.len) return error.BufferTooSmall;

    var str_idx: u8 = num_len;
    var dest_idx: u8 = final_len;
    var digit_count: u8 = 0;

    while (str_idx > 0) {
        if (digit_count == 3) {
            dest_idx -= 1;
            buffer[dest_idx] = ',';
            digit_count = 0;
        }

        dest_idx -= 1;
        str_idx -= 1;

        // TODO: support float
        if (!isDigit(num_str[str_idx])) {
            return error.InvalidInput;
        }

        buffer[dest_idx] = num_str[str_idx];
        digit_count += 1;
    }

    return buffer[0..@as(usize, final_len)];
}
