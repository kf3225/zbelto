const std = @import("std");
const default_allocator = @import("root.zig").default_allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const BasicServer = @import("server.zig").BasicServer;
const HttpRequest = @import("request.zig").HttpRequest;
const HttpResponse = @import("response.zig").HttpResponse;
const Router = @import("route.zig").Router;

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    var arena = ArenaAllocator.init(default_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var router = Router.init(allocator);

    _ = try router.addRoute(.GET, "/", &handleRoot).addRoute(.GET, "/users", &handleListUser).addRoute(.POST, "/users", &handleCreateUser).build();

    var basic_server = try BasicServer.init(.{});
    defer basic_server.deinit();
    _ = try basic_server.add_router(router);

    try basic_server.listen();
}

fn handleRoot(req: HttpRequest) !HttpResponse {
    std.debug.print("Root {}\n", .{req});
    return HttpResponse{
        .status_code = 200,
        .status_message = "OK",
        .body = "Hello, World!",
    };
}

fn handleListUser(req: HttpRequest) !HttpResponse {
    std.debug.print("List User\n{}\n", .{req});
    return HttpResponse{
        .status_code = 200,
        .status_message = "OK",
        .body = "Hello, Users!",
    };
}

fn handleCreateUser(req: HttpRequest) !HttpResponse {
    std.debug.print("Create User\n{}\n", .{req});
    return HttpResponse{
        .status_code = 200,
        .status_message = "OK",
        .body = "Hello, Users!",
    };
}
