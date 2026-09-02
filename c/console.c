typedef unsigned char byte;
typedef unsigned short word;

extern void serial_put(byte value);
extern volatile unsigned int timer_ticks;

static volatile word *video = (volatile word *)0xb8000;
static unsigned int cursor = 14 * 80;
static char line[128];
static unsigned int length;

static void scroll_console(void) {
    unsigned int row;
    unsigned int column;

    for (row = 14; row < 24; row++) {
        for (column = 0; column < 80; column++) {
            video[row * 80 + column] = video[(row + 1) * 80 + column];
        }
    }
    for (column = 0; column < 80; column++) {
        video[24 * 80 + column] = 0x0f20;
    }
    cursor = 24 * 80;
}

static void draw(byte value) {
    serial_put(value);
    if (value == 0) {
        return;
    }
    if (value == 8) {
        if (cursor > 14 * 80) {
            cursor--;
            video[cursor] = 0x0f20;
        }
        return;
    }
    //scrolling is very important
    if (value == 10) {
        cursor = ((cursor / 80) + 1) * 80;
        if (cursor >= 25 * 80) {
            scroll_console();
        }
        return;
    }
    if (value == 9) {
        cursor = (cursor + 8) & ~7u;
        return;
    }
    video[cursor] = ((word)0x0f << 8) | value;
    cursor++;
    if (cursor >= 25 * 80) {
        cursor = 14 * 80;
        scroll_console();
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
    for (index = 14 * 80; index < 25 * 80; index++) {
        video[index] = 0x0f20;
    }
    cursor = 14 * 80;
}

static void clear_screen(void) {
    unsigned int index;
    for (index = 0; index < 25 * 80; index++) {
        video[index] = 0x0f20;
    }
    cursor = 14 * 80;
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

void start_console(void) {
    unsigned int end;

    length = 0;
    clear_screen();
    cursor = 10 * 80 + 34;
    text("VEIL");
    cursor = 11 * 80 + 25;
    text("x32 protected mode");
    cursor = 12 * 80 + 24;
    text("starting console...");
    end = timer_ticks + 500;
    while (timer_ticks < end) {
    }
    clear_console();
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
