pub const HttpResponse = struct {
    status_code: u16,
    status_message: []const u8,
    body: []const u8,
};
