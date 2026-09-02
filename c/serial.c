typedef unsigned char byte;
typedef unsigned short word;

extern byte inb(word port);
extern void outb(word port, byte value);
extern void io_wait(void);

static const word data = 0x3f8;
static const word interrupt = 0x3f9;
static const word line = 0x3fb;
static const word fifo = 0x3fa;
static const word modem = 0x3fc;
static const word status = 0x3fd;

void init_serial(void) {
    outb(interrupt, 0);
    outb(line, 0x80);
    outb(data, 3);
    outb(interrupt, 0);
    outb(line, 3);
    outb(fifo, 0xc7);
    outb(modem, 0x0b);
    io_wait();
}

void serial_put(byte value) {
    while ((inb(status) & 0x20) == 0) {
    }
    outb(data, value);
}
