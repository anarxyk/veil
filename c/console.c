typedef unsigned char byte;
typedef unsigned short word;

extern void serial_put(byte value);

static volatile word *video = (volatile word *)0xb8000;
static unsigned int cursor = 12 * 80;

void console_put(byte value) {
    serial_put(value);
    if (value == 0) {
        return;
    }
    if (value == 8) {
        if (cursor > 12 * 80) {
            cursor--;
            video[cursor] = 0x0f20;
        }
        return;
    }
    if (value == 10) {
        cursor = ((cursor / 80) + 1) * 80;
        return;
    }
    if (value == 9) {
        cursor = (cursor + 8) & ~7u;
        return;
    }
    video[cursor] = ((word)0x0f << 8) | value;
    cursor++;
    if (cursor >= 25 * 80) {
        cursor = 12 * 80;
    }
}
