pub const MAX_LEN = 64;
pub const WORDS_MAX_LEN = 1024;

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

const ones = [20][]const u8{
    "", "one", "two", "three", "four", "five",
    "six", "seven", "eight", "nine", "ten",
    "eleven", "twelve", "thirteen", "fourteen", "fifteen",
    "sixteen", "seventeen", "eighteen", "nineteen",
};

// [0] unused, [1] unused (10-19 are handled by the ones table above)
const tens_table = [10][]const u8{
    "", "", "twenty", "thirty", "forty", "fifty",
    "sixty", "seventy", "eighty", "ninety",
};

const scale_names = [8][]const u8{
    "", "thousand", "million", "billion", "trillion",
    "quadrillion", "quintillion", "sextillion",
};

fn appendSlice(buffer: []u8, pos: usize, src: []const u8) usize {
    for (src, 0..) |c, i| {
        buffer[pos + i] = c;
    }
    return pos + src.len;
}

// Convert a group value (0-999) to words, writing into buffer at pos.
fn groupToWords(n: u16, buffer: []u8, pos: usize) usize {
    if (n == 0) return pos;
    var val = n;
    var p = pos;

    if (val >= 100) {
        p = appendSlice(buffer, p, ones[val / 100]);
        p = appendSlice(buffer, p, " hundred");
        val = val % 100;
        if (val > 0) {
            p = appendSlice(buffer, p, " and ");
        }
    }

    if (val >= 20) {
        p = appendSlice(buffer, p, tens_table[val / 10]);
        const remainder = val % 10;
        if (remainder > 0) {
            buffer[p] = '-';
            p += 1;
            p = appendSlice(buffer, p, ones[remainder]);
        }
    } else if (val > 0) {
        p = appendSlice(buffer, p, ones[val]);
    }

    return p;
}

// Assumes input is already validated (digits only, no leading zeros except "0").
pub fn numberToWords(num_str: []const u8, buffer: []u8) ![]const u8 {
    // Handle zero
    if (num_str.len == 1 and num_str[0] == '0') {
        const zero = "Zero";
        @memcpy(buffer[0..zero.len], zero);
        return buffer[0..zero.len];
    }

    // Parse groups of 3 from right to left
    var group_values: [8]u16 = .{ 0, 0, 0, 0, 0, 0, 0, 0 };
    var num_groups: usize = 0;
    var i: usize = num_str.len;
    while (i > 0) {
        var group_val: u16 = 0;
        var multiplier: u16 = 1;
        const group_start = if (i >= 3) i - 3 else 0;
        var j: usize = i;
        while (j > group_start) {
            j -= 1;
            group_val += @as(u16, num_str[j] - '0') * multiplier;
            multiplier *= 10;
        }
        group_values[num_groups] = group_val;
        num_groups += 1;
        i = group_start;
    }

    // Write groups from highest to lowest
    var pos: usize = 0;
    var written_groups: usize = 0;
    var gi: usize = num_groups;
    while (gi > 0) {
        gi -= 1;
        const val = group_values[gi];
        if (val > 0) {
            if (written_groups > 0) {
                buffer[pos] = ' ';
                pos += 1;
            }

            // Insert "and" before the last nonzero group if it's < 100
            // and there are already higher-order parts written
            if (gi == 0 and val < 100 and written_groups > 0) {
                pos = appendSlice(buffer, pos, "and ");
            }

            pos = groupToWords(val, buffer, pos);

            if (scale_names[gi].len > 0) {
                buffer[pos] = ' ';
                pos += 1;
                pos = appendSlice(buffer, pos, scale_names[gi]);
            }

            written_groups += 1;
        }
    }

    // Capitalize first letter
    if (pos > 0 and buffer[0] >= 'a' and buffer[0] <= 'z') {
        buffer[0] = buffer[0] - 32;
    }

    return buffer[0..pos];
}
