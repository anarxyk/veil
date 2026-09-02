typedef unsigned char byte;
typedef unsigned short word;

extern void serial_put(byte value);

static volatile word *video = (volatile word *)0xb8000;
static unsigned int cursor = 13 * 80;
static char line[128];
static unsigned int length;

static void draw(byte value) {
    serial_put(value);
    if (value == 0) {
        return;
    }
    if (value == 8) {
        if (cursor > 13 * 80) {
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
        cursor = 13 * 80;
    }
}

static void text(const char *value) {
    while (*value) {
        draw((byte)*value);
        value++;
    }
}

static int same(const char *left, const char *right) {
    while (*left && *right && *left == *right) {
        left++;
        right++;
    }
    return *left == 0 && *right == 0;
}

static void clear_console(void) {
    unsigned int index;
    for (index = 13 * 80; index < 25 * 80; index++) {
        video[index] = 0x0f20;
    }
    cursor = 13 * 80;
}

static void prompt(void) {
    text("> ");
}

static void command(void) {
    if (same(line, "help")) {
        text("help clear info echo");
    } else if (same(line, "clear")) {
        clear_console();
    } else if (same(line, "info")) {
        text("veil x32 kernel");
    } else if (length >= 5 && line[0] == 'e' && line[1] == 'c' && line[2] == 'h' && line[3] == 'o' && line[4] == ' ') {
        text(line + 5);
    } else if (length != 0) {
        text("unknown command");
    }
}

void init_console(void) {
    length = 0;
    prompt();
}

void console_put(byte value) {
    if (value == 8) {
        if (length != 0) {
            length--;
            line[length] = 0;
            draw(8);
        }
        return;
    }
    if (value == 10) {
        draw(10);
        line[length] = 0;
        command();
        draw(10);
        length = 0;
        prompt();
        return;
    }
    if (value < 32 || length >= sizeof(line) - 1) {
        return;
    }
    line[length++] = (char)value;
    line[length] = 0;
    draw(value);
}
