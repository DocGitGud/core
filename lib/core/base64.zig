const std = @import("std");
const expect = std.testing.expect;

const base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

pub fn encode(input: []const u8, allocator: std.mem.Allocator) ![]u8 {
    std.debug.print("input: {s}", .{input});
    if (input.len == 0) {
        return "";
    }

    const output_len = try calcEncodeLength(input);
    const output = try allocator.alloc(u8, output_len);
    var buf = [3]u8{ 0, 0, 0 };

    var idx: usize = 0;
    var iout: u64 = 0;
    while (idx <= input.len - 3) : (idx += 3) {
        buf[0] = input[idx];
        buf[1] = input[idx + 1];
        buf[2] = input[idx + 2];

        output[iout] = charAt(buf[0] >> 2);
        output[iout + 1] = charAt(((buf[0] & 0x03) << 4) + (buf[1] >> 4));
        output[iout + 2] = charAt(((buf[1] & 0x0f) << 2) + (buf[2] >> 6));
        output[iout + 3] = charAt(buf[2] & 0x3f);

        iout += 4;
    }

    const remainder: usize = input.len % 3;
    if (remainder == 1) {
        buf[0] = input[idx];

        output[iout] = charAt(buf[0] >> 2);
        output[iout + 1] = charAt((buf[0] & 0x03) << 4);
        output[iout + 2] = '=';
        output[iout + 3] = '=';
    }

    if (remainder == 2) {
        buf[0] = input[idx];
        buf[1] = input[idx + 1];

        output[iout] = charAt(buf[0] >> 2);
        output[iout + 1] = charAt(((buf[0] & 0x03) << 4) + (buf[1] >> 4));
        output[iout + 2] = charAt((buf[1] & 0x0f) << 2);
        output[iout + 3] = '=';
    }

    return output;
}

pub fn decode(input: []const u8, allocator: std.mem.Allocator) ![]u8 {
    std.debug.print("input: {s}", .{input});
    if (input.len == 0) {
        return "";
    }

    const output_len = try calcDecodeLength(input);
    var output = try allocator.alloc(u8, output_len);
    var buf = [4]u8{ 0, 0, 0, 0 };

    var idx: usize = 0;
    var iout: u64 = 0;
    while (idx <= input.len - 4) : (idx += 4) {
        buf[0] = charIndex(input[idx]);
        buf[1] = charIndex(input[idx + 1]);
        buf[2] = charIndex(input[idx + 2]);
        buf[3] = charIndex(input[idx + 3]);

        output[iout] = (buf[0] << 2) + (buf[1] >> 4);
        if (buf[2] != 64) {
            output[iout + 1] = (buf[1] << 4) + (buf[2] >> 2);
        }
        if (buf[3] != 64) {
            output[iout + 2] = (buf[2] << 6) + buf[3];
        }

        iout += 3;
    }

    return output;
}

// ---------- Helpers
fn charAt(index: usize) u8 {
    return base64[index];
}

fn charIndex(char: u8) u8 {
    if (char == '=')
        return 64;
    var index: u8 = 0;
    for (0..63) |i| {
        if (charAt(i) == char)
            break;
        index += 1;
    }

    return index;
}

fn calcEncodeLength(input: []const u8) !usize {
    if (input.len < 3) {
        return 4;
    }

    const num_groups: usize = try std.math.divCeil(usize, input.len, 3);
    const num_u6 = num_groups * 4;
    return num_u6;
}

fn calcDecodeLength(input: []const u8) !usize {
    if (input.len < 4) {
        return 3;
    }

    const num_groups: usize = try std.math.divFloor(usize, input.len, 4);
    var num_u8: usize = num_groups * 3;
    var i: usize = input.len - 1;
    while (i > 0) : (i -= 1) {
        if (input[i] == '=') {
            num_u8 -= 1;
        } else {
            break;
        }
    }

    return num_u8;
}
// Helpers ----------

// ---------- Tests
test "[ encode ]" {
    var da = std.heap.DebugAllocator(.{}){};
    const allocator = da.allocator();

    const output_1 = try encode("Testing things and stuff", allocator);
    defer allocator.free(output_1);
    try expect(std.mem.eql(u8, output_1, "VGVzdGluZyB0aGluZ3MgYW5kIHN0dWZm"));

    const output_2 = try encode("Testing Thing and Stuff", allocator);
    defer allocator.free(output_2);
    try expect(std.mem.eql(u8, output_2, "VGVzdGluZyBUaGluZyBhbmQgU3R1ZmY="));

    const output_3 = try encode("Testin thing and stuff", allocator);
    defer allocator.free(output_3);
    try expect(std.mem.eql(u8, output_3, "VGVzdGluIHRoaW5nIGFuZCBzdHVmZg=="));
}

test "[ decode ]" {
    var da = std.heap.DebugAllocator(.{}){};
    const allocator = da.allocator();

    const output_1 = try decode("VGVzdGluZyBzdHVmZiBhbmQgdGhpbmdz", allocator);
    defer allocator.free(output_1);
    try expect(std.mem.eql(u8, output_1, "Testing stuff and things"));

    const output_2 = try decode("VGVzdGluZyBTdHVmZiBhbmQgVGhpbmc=", allocator);
    defer allocator.free(output_2);
    try expect(std.mem.eql(u8, output_2, "Testing Stuff and Thing"));

    const output_3 = try decode("VGVzdGluIHN0dWZmIGFuZCB0aGluZw==", allocator);
    defer allocator.free(output_3);
    try expect(std.mem.eql(u8, output_3, "Testin stuff and thing"));
}
// Tests ----------
