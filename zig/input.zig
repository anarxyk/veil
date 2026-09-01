const byte = u8;

const KeyEvent = extern struct {
    ascii: byte,
    key: byte,
    state: byte,
    flags: byte,
};

extern fn keyboard_read(event: *KeyEvent) callconv(.c) c_int;
extern fn console_put(value: byte) callconv(.c) void;

export fn input_poll() callconv(.c) void {
    var event: KeyEvent = undefined;
    while (keyboard_read(&event) != 0) {
        if (event.state != 0) continue;
        console_put(event.ascii);
    }
}
