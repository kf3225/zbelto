const std = @import("std");
const StringHashMap = std.StringHashMap;
const HttpRequest = @import("request.zig").HttpRequest;
const HttpResponse = @import("response.zig").HttpResponse;
const Allocator = std.mem.Allocator;
const Method = std.http.Method;

const Route = struct {
    method: Method,
    path: []const u8,
    handler: *const fn (HttpRequest) anyerror!HttpResponse,
};

pub const Router = struct {
    routes: StringHashMap(Route),
    allocator: Allocator,
    error_state: ?anyerror,

    pub fn init(allocator: Allocator) @This() {
        return .{
            .routes = StringHashMap(Route).init(allocator),
            .allocator = allocator,
            .error_state = null,
        };
    }

    pub fn addRoute(
        self: *@This(),
        method: Method,
        path: []const u8,
        handler: *const fn (HttpRequest) anyerror!HttpResponse,
    ) *@This() {
        const key = std.fmt.allocPrint(self.allocator, "{s}-{s}", .{
            @tagName(method),
            path,
        }) catch |err| {
            self.error_state = err;
            return self;
        };
        self.routes.put(key, Route{
            .handler = handler,
            .method = method,
            .path = path,
        }) catch |err| {
            self.error_state = err;
            return self;
        };
        return self;
    }
    pub fn build(self: @This()) !@This() {
        if (self.error_state) |err| {
            return err;
        }
        return self;
    }

    pub fn handleRequest(self: @This(), request: HttpRequest) ![]const u8 {
        const key = try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{
            @tagName(request.method),
            request.path,
        });

        if (self.routes.get(key)) |route| {
            const response = try route.handler(request);
            return try self.parseResponse(response);
        }

        return try self.parseResponse(HttpResponse{
            .status_code = 404,
            .status_message = "NOT FOUND",
            .body = "NOT FOUND",
        });
    }

    fn parseResponse(self: @This(), response: HttpResponse) ![]const u8 {
        const raw_response = try std.fmt.allocPrint(self.allocator, "HTTP/1.1 {d} OK\r\n" ++
            "Content-Type: text/plain\r\n" ++
            "Content-Length: {d}\r\n" ++
            "\r\n" ++
            "{s}\r\n", .{
            response.status_code,
            response.body.len,
            response.body,
        });

        return raw_response;
    }
};
