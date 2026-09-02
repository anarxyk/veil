typedef unsigned char byte;
typedef unsigned short word;
typedef unsigned int flags_t;

extern byte inb(word port);
extern void outb(word port, byte value);
extern void io_wait(void);
extern flags_t irq_save(void);
extern void irq_restore(flags_t flags);

static const word data = 0x3f8;
static const word interrupt = 0x3f9;
static const word line = 0x3fb;
static const word fifo = 0x3fa;
static const word modem = 0x3fc;
static const word status = 0x3fd;

static volatile byte tx_queue[256];
static volatile byte rx_queue[256];
static volatile byte tx_head;
static volatile byte tx_tail;
static volatile byte rx_head;
static volatile byte rx_tail;

static void send_now(byte value) {
    while ((inb(status) & 0x20) == 0) {
    }
    outb(data, value);
}

void init_serial(void) {
    outb(interrupt, 0);
    outb(line, 0x80);
    outb(data, 3);
    outb(interrupt, 0);
    outb(line, 3);
    outb(fifo, 0xc7);
    outb(modem, 0x0b);
    tx_head = 0;
    tx_tail = 0;
    rx_head = 0;
    rx_tail = 0;
    outb(interrupt, 1);
    io_wait();
}

void serial_put(byte value) {
    flags_t flags = irq_save();
    byte next = tx_head + 1;

    if ((flags & 0x200) == 0) {
        irq_restore(flags);
        send_now(value);
        return;
    }
    if (next != tx_tail) {
        tx_queue[tx_head] = value;
        tx_head = next;
        outb(interrupt, inb(interrupt) | 2);
    }
    irq_restore(flags);
}

void serial_irq(void) {
    while ((inb(status) & 1) != 0) {
        byte value = inb(data);
        byte next = rx_head + 1;
        if (next != rx_tail) {
            rx_queue[rx_head] = value;
            rx_head = next;
        }
    }
    while ((inb(status) & 0x20) != 0 && tx_tail != tx_head) {
        outb(data, tx_queue[tx_tail]);
        tx_tail++;
    }
    if (tx_tail == tx_head) {
        outb(interrupt, inb(interrupt) & 0xfd);
    }
}

int serial_get(void) {
    flags_t flags = irq_save();
    byte value;

    if (rx_tail == rx_head) {
        irq_restore(flags);
        return -1;
    }
    value = rx_queue[rx_tail];
    rx_tail++;
    irq_restore(flags);
    return value;
}
