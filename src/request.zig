const std = @import("std");
const Stream = std.net.Stream;
const StringHashMap = std.StringHashMap;
const Allocator = std.mem.Allocator;
const Method = std.http.Method;
const testing = std.testing;

pub const HttpRequest = struct {
    allocator: Allocator,
    method: Method = undefined,
    path: []const u8 = undefined,
    headers: StringHashMap([]const u8) = undefined,
    body: []const u8 = undefined,

    const HttpError = error{
        InvalidRequestLine,
        MissingHeaders,
        InvalidMethod,
        InvalidPath,
        InvalidProtocol,
    };

    pub fn fromStream(allocator: Allocator, stream: Stream) !HttpRequest {
        // raw request comes like bellow format:
        //
        // GET /index.html HTTP/1.1\r\n
        // Host: example.com\r\n
        // User-Agent: Mozilla/5.0\r\n
        // Accept: text/html\r\n
        // \r\n
        var buf = try allocator.alloc(u8, 4096);

        const bytes_read = try stream.read(buf);
        const raw_request = buf[0..bytes_read];
        std.debug.print("{s}", .{raw_request});

        var lines = std.mem.split(u8, raw_request, "\r\n");
        const first_line = try allocator.dupe(u8, lines.next() orelse return HttpError.InvalidRequestLine);

        var parts = std.mem.split(u8, first_line, " ");
        const method_str = try allocator.dupe(u8, parts.next() orelse return HttpError.InvalidRequestLine);
        const path = try allocator.dupe(u8, parts.next() orelse return HttpError.InvalidRequestLine);

        var headers = StringHashMap([]const u8).init(allocator);
        while (lines.next()) |line| {
            if (line.len == 0) break;
            if (std.mem.indexOf(u8, line, ":")) |separator| {
                const key = line[0..separator];
                const value = line[separator + 2 ..];
                try headers.put(key, value);
            }
        }
        const body = lines.rest();
        const method = std.meta.stringToEnum(Method, method_str) orelse return HttpError.InvalidMethod;

        return .{
            .allocator = allocator,
            .body = body,
            .method = method,
            .path = path,
            .headers = headers,
        };
    }
};
