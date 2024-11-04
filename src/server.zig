const std = @import("std");
const default_allocator = @import("root.zig").default_allocator;
const HttpRequest = @import("request.zig").HttpRequest;
const Router = @import("route.zig").Router;
const StringHashMap = std.StringHashMap;
const Allocator = std.mem.Allocator;
const Server = std.net.Server;
const Stream = std.net.Stream;
const Address = std.net.Address;
const Method = std.http.Method;
const Connection = std.net.Server.Connection;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const ArenaAllocator = std.heap.ArenaAllocator;

pub const ServerOption = struct { host: []const u8 = "0.0.0.0", port: u16 = 8000 };

pub const BasicServer = struct {
    server: Server,
    option: ServerOption,
    router: Router = undefined,

    pub fn init(option: ServerOption) !@This() {
        const address = try Address.parseIp(option.host, option.port);

        return .{
            .server = try address.listen(.{}),
            .option = option,
        };
    }

    pub fn add_router(self: *@This(), router: Router) !*@This() {
        if (router.error_state) |err| {
            return err;
        }
        self.router = router;
        return self;
    }

    pub fn deinit(self: *@This()) void {
        self.server.deinit();
    }

    pub fn listen(self: *@This()) !void {
        std.debug.print("Server listening on port {}...\n" ++
            "If yout want stop, press CTRL + C\n", .{self.option.port});

        while (true) {
            const connection: Connection = try self.server.accept();
            {
                defer connection.stream.close();
                try self.handleConnection(connection);
            }
        }
    }

    fn handleConnection(self: @This(), connection: Connection) !void {
        var arena = ArenaAllocator.init(default_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        const request = try HttpRequest.fromStream(allocator, connection.stream);
        const response = try self.router.handleRequest(request);

        try connection.stream.writeAll(response);
    }
};
