
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 a0 18 10 f0       	push   $0xf01018a0
f0100050:	e8 40 09 00 00       	call   f0100995 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 fa 06 00 00       	call   f0100775 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 bc 18 10 f0       	push   $0xf01018bc
f0100087:	e8 09 09 00 00       	call   f0100995 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 40 29 11 f0       	mov    $0xf0112940,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 4e 13 00 00       	call   f01013ff <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 9d 04 00 00       	call   f0100553 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 d7 18 10 f0       	push   $0xf01018d7
f01000c3:	e8 cd 08 00 00       	call   f0100995 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 34 07 00 00       	call   f0100815 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 44 29 11 f0 00 	cmpl   $0x0,0xf0112944
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 44 29 11 f0    	mov    %esi,0xf0112944

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 f2 18 10 f0       	push   $0xf01018f2
f0100110:	e8 80 08 00 00       	call   f0100995 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 50 08 00 00       	call   f010096f <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 2e 19 10 f0 	movl   $0xf010192e,(%esp)
f0100126:	e8 6a 08 00 00       	call   f0100995 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 dd 06 00 00       	call   f0100815 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 0a 19 10 f0       	push   $0xf010190a
f0100152:	e8 3e 08 00 00       	call   f0100995 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 0c 08 00 00       	call   f010096f <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 2e 19 10 f0 	movl   $0xf010192e,(%esp)
f010016a:	e8 26 08 00 00       	call   f0100995 <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f8 00 00 00    	je     f01002df <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001e7:	a8 20                	test   $0x20,%al
f01001e9:	0f 85 f6 00 00 00    	jne    f01002e5 <kbd_proc_data+0x10c>
f01001ef:	ba 60 00 00 00       	mov    $0x60,%edx
f01001f4:	ec                   	in     (%dx),%al
f01001f5:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001f7:	3c e0                	cmp    $0xe0,%al
f01001f9:	75 0d                	jne    f0100208 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001fb:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100202:	b8 00 00 00 00       	mov    $0x0,%eax
f0100207:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100208:	55                   	push   %ebp
f0100209:	89 e5                	mov    %esp,%ebp
f010020b:	53                   	push   %ebx
f010020c:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010020f:	84 c0                	test   %al,%al
f0100211:	79 36                	jns    f0100249 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100213:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100219:	89 cb                	mov    %ecx,%ebx
f010021b:	83 e3 40             	and    $0x40,%ebx
f010021e:	83 e0 7f             	and    $0x7f,%eax
f0100221:	85 db                	test   %ebx,%ebx
f0100223:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100226:	0f b6 d2             	movzbl %dl,%edx
f0100229:	0f b6 82 80 1a 10 f0 	movzbl -0xfefe580(%edx),%eax
f0100230:	83 c8 40             	or     $0x40,%eax
f0100233:	0f b6 c0             	movzbl %al,%eax
f0100236:	f7 d0                	not    %eax
f0100238:	21 c8                	and    %ecx,%eax
f010023a:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f010023f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100244:	e9 a4 00 00 00       	jmp    f01002ed <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100249:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010024f:	f6 c1 40             	test   $0x40,%cl
f0100252:	74 0e                	je     f0100262 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100254:	83 c8 80             	or     $0xffffff80,%eax
f0100257:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100259:	83 e1 bf             	and    $0xffffffbf,%ecx
f010025c:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100262:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 82 80 1a 10 f0 	movzbl -0xfefe580(%edx),%eax
f010026c:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100272:	0f b6 8a 80 19 10 f0 	movzbl -0xfefe680(%edx),%ecx
f0100279:	31 c8                	xor    %ecx,%eax
f010027b:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100280:	89 c1                	mov    %eax,%ecx
f0100282:	83 e1 03             	and    $0x3,%ecx
f0100285:	8b 0c 8d 60 19 10 f0 	mov    -0xfefe6a0(,%ecx,4),%ecx
f010028c:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100290:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100293:	a8 08                	test   $0x8,%al
f0100295:	74 1b                	je     f01002b2 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100297:	89 da                	mov    %ebx,%edx
f0100299:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010029c:	83 f9 19             	cmp    $0x19,%ecx
f010029f:	77 05                	ja     f01002a6 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f01002a1:	83 eb 20             	sub    $0x20,%ebx
f01002a4:	eb 0c                	jmp    f01002b2 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f01002a6:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a9:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002ac:	83 fa 19             	cmp    $0x19,%edx
f01002af:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002b2:	f7 d0                	not    %eax
f01002b4:	a8 06                	test   $0x6,%al
f01002b6:	75 33                	jne    f01002eb <kbd_proc_data+0x112>
f01002b8:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002be:	75 2b                	jne    f01002eb <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01002c0:	83 ec 0c             	sub    $0xc,%esp
f01002c3:	68 24 19 10 f0       	push   $0xf0101924
f01002c8:	e8 c8 06 00 00       	call   f0100995 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002cd:	ba 92 00 00 00       	mov    $0x92,%edx
f01002d2:	b8 03 00 00 00       	mov    $0x3,%eax
f01002d7:	ee                   	out    %al,(%dx)
f01002d8:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
f01002dd:	eb 0e                	jmp    f01002ed <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002e4:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002ea:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002eb:	89 d8                	mov    %ebx,%eax
}
f01002ed:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002f0:	c9                   	leave  
f01002f1:	c3                   	ret    

f01002f2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002f2:	55                   	push   %ebp
f01002f3:	89 e5                	mov    %esp,%ebp
f01002f5:	57                   	push   %edi
f01002f6:	56                   	push   %esi
f01002f7:	53                   	push   %ebx
f01002f8:	83 ec 1c             	sub    $0x1c,%esp
f01002fb:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002fd:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100302:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100307:	b9 84 00 00 00       	mov    $0x84,%ecx
f010030c:	eb 09                	jmp    f0100317 <cons_putc+0x25>
f010030e:	89 ca                	mov    %ecx,%edx
f0100310:	ec                   	in     (%dx),%al
f0100311:	ec                   	in     (%dx),%al
f0100312:	ec                   	in     (%dx),%al
f0100313:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100314:	83 c3 01             	add    $0x1,%ebx
f0100317:	89 f2                	mov    %esi,%edx
f0100319:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 08                	jne    f0100326 <cons_putc+0x34>
f010031e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100324:	7e e8                	jle    f010030e <cons_putc+0x1c>
f0100326:	89 f8                	mov    %edi,%eax
f0100328:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010032b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100330:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100331:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100336:	be 79 03 00 00       	mov    $0x379,%esi
f010033b:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100340:	eb 09                	jmp    f010034b <cons_putc+0x59>
f0100342:	89 ca                	mov    %ecx,%edx
f0100344:	ec                   	in     (%dx),%al
f0100345:	ec                   	in     (%dx),%al
f0100346:	ec                   	in     (%dx),%al
f0100347:	ec                   	in     (%dx),%al
f0100348:	83 c3 01             	add    $0x1,%ebx
f010034b:	89 f2                	mov    %esi,%edx
f010034d:	ec                   	in     (%dx),%al
f010034e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100354:	7f 04                	jg     f010035a <cons_putc+0x68>
f0100356:	84 c0                	test   %al,%al
f0100358:	79 e8                	jns    f0100342 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010035a:	ba 78 03 00 00       	mov    $0x378,%edx
f010035f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100363:	ee                   	out    %al,(%dx)
f0100364:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100369:	b8 0d 00 00 00       	mov    $0xd,%eax
f010036e:	ee                   	out    %al,(%dx)
f010036f:	b8 08 00 00 00       	mov    $0x8,%eax
f0100374:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100375:	89 fa                	mov    %edi,%edx
f0100377:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010037d:	89 f8                	mov    %edi,%eax
f010037f:	80 cc 07             	or     $0x7,%ah
f0100382:	85 d2                	test   %edx,%edx
f0100384:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100387:	89 f8                	mov    %edi,%eax
f0100389:	0f b6 c0             	movzbl %al,%eax
f010038c:	83 f8 09             	cmp    $0x9,%eax
f010038f:	74 74                	je     f0100405 <cons_putc+0x113>
f0100391:	83 f8 09             	cmp    $0x9,%eax
f0100394:	7f 0a                	jg     f01003a0 <cons_putc+0xae>
f0100396:	83 f8 08             	cmp    $0x8,%eax
f0100399:	74 14                	je     f01003af <cons_putc+0xbd>
f010039b:	e9 99 00 00 00       	jmp    f0100439 <cons_putc+0x147>
f01003a0:	83 f8 0a             	cmp    $0xa,%eax
f01003a3:	74 3a                	je     f01003df <cons_putc+0xed>
f01003a5:	83 f8 0d             	cmp    $0xd,%eax
f01003a8:	74 3d                	je     f01003e7 <cons_putc+0xf5>
f01003aa:	e9 8a 00 00 00       	jmp    f0100439 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01003af:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003b6:	66 85 c0             	test   %ax,%ax
f01003b9:	0f 84 e6 00 00 00    	je     f01004a5 <cons_putc+0x1b3>
			crt_pos--;
f01003bf:	83 e8 01             	sub    $0x1,%eax
f01003c2:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003c8:	0f b7 c0             	movzwl %ax,%eax
f01003cb:	66 81 e7 00 ff       	and    $0xff00,%di
f01003d0:	83 cf 20             	or     $0x20,%edi
f01003d3:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003d9:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003dd:	eb 78                	jmp    f0100457 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003df:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003e6:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003e7:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003ee:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003f4:	c1 e8 16             	shr    $0x16,%eax
f01003f7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003fa:	c1 e0 04             	shl    $0x4,%eax
f01003fd:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100403:	eb 52                	jmp    f0100457 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f0100405:	b8 20 00 00 00       	mov    $0x20,%eax
f010040a:	e8 e3 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010040f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100414:	e8 d9 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100419:	b8 20 00 00 00       	mov    $0x20,%eax
f010041e:	e8 cf fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100423:	b8 20 00 00 00       	mov    $0x20,%eax
f0100428:	e8 c5 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010042d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100432:	e8 bb fe ff ff       	call   f01002f2 <cons_putc>
f0100437:	eb 1e                	jmp    f0100457 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100439:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100440:	8d 50 01             	lea    0x1(%eax),%edx
f0100443:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010044a:	0f b7 c0             	movzwl %ax,%eax
f010044d:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100453:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100457:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010045e:	cf 07 
f0100460:	76 43                	jbe    f01004a5 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100462:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100467:	83 ec 04             	sub    $0x4,%esp
f010046a:	68 00 0f 00 00       	push   $0xf00
f010046f:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100475:	52                   	push   %edx
f0100476:	50                   	push   %eax
f0100477:	e8 d0 0f 00 00       	call   f010144c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010047c:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100482:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100488:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010048e:	83 c4 10             	add    $0x10,%esp
f0100491:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100496:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100499:	39 d0                	cmp    %edx,%eax
f010049b:	75 f4                	jne    f0100491 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010049d:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004a4:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004a5:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004ab:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004b0:	89 ca                	mov    %ecx,%edx
f01004b2:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004b3:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004ba:	8d 71 01             	lea    0x1(%ecx),%esi
f01004bd:	89 d8                	mov    %ebx,%eax
f01004bf:	66 c1 e8 08          	shr    $0x8,%ax
f01004c3:	89 f2                	mov    %esi,%edx
f01004c5:	ee                   	out    %al,(%dx)
f01004c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004cb:	89 ca                	mov    %ecx,%edx
f01004cd:	ee                   	out    %al,(%dx)
f01004ce:	89 d8                	mov    %ebx,%eax
f01004d0:	89 f2                	mov    %esi,%edx
f01004d2:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004d6:	5b                   	pop    %ebx
f01004d7:	5e                   	pop    %esi
f01004d8:	5f                   	pop    %edi
f01004d9:	5d                   	pop    %ebp
f01004da:	c3                   	ret    

f01004db <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004db:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004e2:	74 11                	je     f01004f5 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004e4:	55                   	push   %ebp
f01004e5:	89 e5                	mov    %esp,%ebp
f01004e7:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004ea:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004ef:	e8 a2 fc ff ff       	call   f0100196 <cons_intr>
}
f01004f4:	c9                   	leave  
f01004f5:	f3 c3                	repz ret 

f01004f7 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004f7:	55                   	push   %ebp
f01004f8:	89 e5                	mov    %esp,%ebp
f01004fa:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004fd:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f0100502:	e8 8f fc ff ff       	call   f0100196 <cons_intr>
}
f0100507:	c9                   	leave  
f0100508:	c3                   	ret    

f0100509 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100509:	55                   	push   %ebp
f010050a:	89 e5                	mov    %esp,%ebp
f010050c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010050f:	e8 c7 ff ff ff       	call   f01004db <serial_intr>
	kbd_intr();
f0100514:	e8 de ff ff ff       	call   f01004f7 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100519:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010051e:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100524:	74 26                	je     f010054c <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100526:	8d 50 01             	lea    0x1(%eax),%edx
f0100529:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010052f:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100536:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100538:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010053e:	75 11                	jne    f0100551 <cons_getc+0x48>
			cons.rpos = 0;
f0100540:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100547:	00 00 00 
f010054a:	eb 05                	jmp    f0100551 <cons_getc+0x48>
		return c;
	}
	return 0;
f010054c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100551:	c9                   	leave  
f0100552:	c3                   	ret    

f0100553 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100553:	55                   	push   %ebp
f0100554:	89 e5                	mov    %esp,%ebp
f0100556:	57                   	push   %edi
f0100557:	56                   	push   %esi
f0100558:	53                   	push   %ebx
f0100559:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010055c:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100563:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010056a:	5a a5 
	if (*cp != 0xA55A) {
f010056c:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100573:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100577:	74 11                	je     f010058a <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100579:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100580:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100583:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100588:	eb 16                	jmp    f01005a0 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010058a:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100591:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f0100598:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010059b:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005a0:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f01005a6:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ab:	89 fa                	mov    %edi,%edx
f01005ad:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ae:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b1:	89 da                	mov    %ebx,%edx
f01005b3:	ec                   	in     (%dx),%al
f01005b4:	0f b6 c8             	movzbl %al,%ecx
f01005b7:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ba:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005bf:	89 fa                	mov    %edi,%edx
f01005c1:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c2:	89 da                	mov    %ebx,%edx
f01005c4:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005c5:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005cb:	0f b6 c0             	movzbl %al,%eax
f01005ce:	09 c8                	or     %ecx,%eax
f01005d0:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005db:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e0:	89 f2                	mov    %esi,%edx
f01005e2:	ee                   	out    %al,(%dx)
f01005e3:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005e8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005ed:	ee                   	out    %al,(%dx)
f01005ee:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005f3:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005f8:	89 da                	mov    %ebx,%edx
f01005fa:	ee                   	out    %al,(%dx)
f01005fb:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100600:	b8 00 00 00 00       	mov    $0x0,%eax
f0100605:	ee                   	out    %al,(%dx)
f0100606:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010060b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100610:	ee                   	out    %al,(%dx)
f0100611:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100616:	b8 00 00 00 00       	mov    $0x0,%eax
f010061b:	ee                   	out    %al,(%dx)
f010061c:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100621:	b8 01 00 00 00       	mov    $0x1,%eax
f0100626:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100627:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010062f:	3c ff                	cmp    $0xff,%al
f0100631:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f0100638:	89 f2                	mov    %esi,%edx
f010063a:	ec                   	in     (%dx),%al
f010063b:	89 da                	mov    %ebx,%edx
f010063d:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010063e:	80 f9 ff             	cmp    $0xff,%cl
f0100641:	75 10                	jne    f0100653 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100643:	83 ec 0c             	sub    $0xc,%esp
f0100646:	68 30 19 10 f0       	push   $0xf0101930
f010064b:	e8 45 03 00 00       	call   f0100995 <cprintf>
f0100650:	83 c4 10             	add    $0x10,%esp
}
f0100653:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100656:	5b                   	pop    %ebx
f0100657:	5e                   	pop    %esi
f0100658:	5f                   	pop    %edi
f0100659:	5d                   	pop    %ebp
f010065a:	c3                   	ret    

f010065b <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010065b:	55                   	push   %ebp
f010065c:	89 e5                	mov    %esp,%ebp
f010065e:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100661:	8b 45 08             	mov    0x8(%ebp),%eax
f0100664:	e8 89 fc ff ff       	call   f01002f2 <cons_putc>
}
f0100669:	c9                   	leave  
f010066a:	c3                   	ret    

f010066b <getchar>:

int
getchar(void)
{
f010066b:	55                   	push   %ebp
f010066c:	89 e5                	mov    %esp,%ebp
f010066e:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100671:	e8 93 fe ff ff       	call   f0100509 <cons_getc>
f0100676:	85 c0                	test   %eax,%eax
f0100678:	74 f7                	je     f0100671 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010067a:	c9                   	leave  
f010067b:	c3                   	ret    

f010067c <iscons>:

int
iscons(int fdnum)
{
f010067c:	55                   	push   %ebp
f010067d:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010067f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100684:	5d                   	pop    %ebp
f0100685:	c3                   	ret    

f0100686 <read_ebp>:
	asm volatile("pushl %0; popfl" : : "r" (eflags));
}

static inline uint32_t
read_ebp(void)
{
f0100686:	55                   	push   %ebp
f0100687:	89 e5                	mov    %esp,%ebp
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100689:	89 e8                	mov    %ebp,%eax
	return ebp;
}
f010068b:	5d                   	pop    %ebp
f010068c:	c3                   	ret    

f010068d <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010068d:	55                   	push   %ebp
f010068e:	89 e5                	mov    %esp,%ebp
f0100690:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100693:	68 80 1b 10 f0       	push   $0xf0101b80
f0100698:	68 9e 1b 10 f0       	push   $0xf0101b9e
f010069d:	68 a3 1b 10 f0       	push   $0xf0101ba3
f01006a2:	e8 ee 02 00 00       	call   f0100995 <cprintf>
f01006a7:	83 c4 0c             	add    $0xc,%esp
f01006aa:	68 4c 1c 10 f0       	push   $0xf0101c4c
f01006af:	68 ac 1b 10 f0       	push   $0xf0101bac
f01006b4:	68 a3 1b 10 f0       	push   $0xf0101ba3
f01006b9:	e8 d7 02 00 00       	call   f0100995 <cprintf>
	return 0;
}
f01006be:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c3:	c9                   	leave  
f01006c4:	c3                   	ret    

f01006c5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006c5:	55                   	push   %ebp
f01006c6:	89 e5                	mov    %esp,%ebp
f01006c8:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006cb:	68 b5 1b 10 f0       	push   $0xf0101bb5
f01006d0:	e8 c0 02 00 00       	call   f0100995 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006d5:	83 c4 08             	add    $0x8,%esp
f01006d8:	68 0c 00 10 00       	push   $0x10000c
f01006dd:	68 74 1c 10 f0       	push   $0xf0101c74
f01006e2:	e8 ae 02 00 00       	call   f0100995 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e7:	83 c4 0c             	add    $0xc,%esp
f01006ea:	68 0c 00 10 00       	push   $0x10000c
f01006ef:	68 0c 00 10 f0       	push   $0xf010000c
f01006f4:	68 9c 1c 10 f0       	push   $0xf0101c9c
f01006f9:	e8 97 02 00 00       	call   f0100995 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006fe:	83 c4 0c             	add    $0xc,%esp
f0100701:	68 91 18 10 00       	push   $0x101891
f0100706:	68 91 18 10 f0       	push   $0xf0101891
f010070b:	68 c0 1c 10 f0       	push   $0xf0101cc0
f0100710:	e8 80 02 00 00       	call   f0100995 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100715:	83 c4 0c             	add    $0xc,%esp
f0100718:	68 00 23 11 00       	push   $0x112300
f010071d:	68 00 23 11 f0       	push   $0xf0112300
f0100722:	68 e4 1c 10 f0       	push   $0xf0101ce4
f0100727:	e8 69 02 00 00       	call   f0100995 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010072c:	83 c4 0c             	add    $0xc,%esp
f010072f:	68 40 29 11 00       	push   $0x112940
f0100734:	68 40 29 11 f0       	push   $0xf0112940
f0100739:	68 08 1d 10 f0       	push   $0xf0101d08
f010073e:	e8 52 02 00 00       	call   f0100995 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100743:	b8 3f 2d 11 f0       	mov    $0xf0112d3f,%eax
f0100748:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010074d:	83 c4 08             	add    $0x8,%esp
f0100750:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100755:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010075b:	85 c0                	test   %eax,%eax
f010075d:	0f 48 c2             	cmovs  %edx,%eax
f0100760:	c1 f8 0a             	sar    $0xa,%eax
f0100763:	50                   	push   %eax
f0100764:	68 2c 1d 10 f0       	push   $0xf0101d2c
f0100769:	e8 27 02 00 00       	call   f0100995 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010076e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100773:	c9                   	leave  
f0100774:	c3                   	ret    

f0100775 <mon_backtrace>:
	return 0;
}*/

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100775:	55                   	push   %ebp
f0100776:	89 e5                	mov    %esp,%ebp
f0100778:	57                   	push   %edi
f0100779:	56                   	push   %esi
f010077a:	53                   	push   %ebx
f010077b:	83 ec 48             	sub    $0x48,%esp
	// Your code here.
	cprintf("Stack backstrace:\n");
f010077e:	68 ce 1b 10 f0       	push   $0xf0101bce
f0100783:	e8 0d 02 00 00       	call   f0100995 <cprintf>
f0100788:	83 c4 10             	add    $0x10,%esp

	uint32_t* ebp;
	uintptr_t eip = 0;
	struct Eipdebuginfo info;

	for (ebp = (uint32_t*)read_ebp; ebp != 0; ebp = (uint32_t*)*ebp)
f010078b:	be 86 06 10 f0       	mov    $0xf0100686,%esi
	{
		eip = *(ebp+1);
f0100790:	8b 46 04             	mov    0x4(%esi),%eax
f0100793:	89 45 c4             	mov    %eax,-0x3c(%ebp)

		cprintf("ebp %08x eip %08x args",(uint32_t)ebp, eip);
f0100796:	83 ec 04             	sub    $0x4,%esp
f0100799:	50                   	push   %eax
f010079a:	56                   	push   %esi
f010079b:	68 e1 1b 10 f0       	push   $0xf0101be1
f01007a0:	e8 f0 01 00 00       	call   f0100995 <cprintf>
f01007a5:	8d 5e 08             	lea    0x8(%esi),%ebx
f01007a8:	8d 7e 1c             	lea    0x1c(%esi),%edi
f01007ab:	83 c4 10             	add    $0x10,%esp
		int i;

		for(i = 2; i < 7; i++)
		{
			cprintf(" %08x", *(ebp+i));
f01007ae:	83 ec 08             	sub    $0x8,%esp
f01007b1:	ff 33                	pushl  (%ebx)
f01007b3:	68 f8 1b 10 f0       	push   $0xf0101bf8
f01007b8:	e8 d8 01 00 00       	call   f0100995 <cprintf>
f01007bd:	83 c3 04             	add    $0x4,%ebx
		eip = *(ebp+1);

		cprintf("ebp %08x eip %08x args",(uint32_t)ebp, eip);
		int i;

		for(i = 2; i < 7; i++)
f01007c0:	83 c4 10             	add    $0x10,%esp
f01007c3:	39 fb                	cmp    %edi,%ebx
f01007c5:	75 e7                	jne    f01007ae <mon_backtrace+0x39>
		{
			cprintf(" %08x", *(ebp+i));
		}
		cprintf("\n");
f01007c7:	83 ec 0c             	sub    $0xc,%esp
f01007ca:	68 2e 19 10 f0       	push   $0xf010192e
f01007cf:	e8 c1 01 00 00       	call   f0100995 <cprintf>
		debuginfo_eip(eip, &info);
f01007d4:	83 c4 08             	add    $0x8,%esp
f01007d7:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007da:	50                   	push   %eax
f01007db:	ff 75 c4             	pushl  -0x3c(%ebp)
f01007de:	e8 bc 02 00 00       	call   f0100a9f <debuginfo_eip>

		cprintf("\t\t%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, info.eip_fn_addr);
f01007e3:	83 c4 08             	add    $0x8,%esp
f01007e6:	ff 75 e0             	pushl  -0x20(%ebp)
f01007e9:	ff 75 d8             	pushl  -0x28(%ebp)
f01007ec:	ff 75 dc             	pushl  -0x24(%ebp)
f01007ef:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007f2:	ff 75 d0             	pushl  -0x30(%ebp)
f01007f5:	68 fe 1b 10 f0       	push   $0xf0101bfe
f01007fa:	e8 96 01 00 00       	call   f0100995 <cprintf>

	uint32_t* ebp;
	uintptr_t eip = 0;
	struct Eipdebuginfo info;

	for (ebp = (uint32_t*)read_ebp; ebp != 0; ebp = (uint32_t*)*ebp)
f01007ff:	8b 36                	mov    (%esi),%esi
f0100801:	83 c4 20             	add    $0x20,%esp
f0100804:	85 f6                	test   %esi,%esi
f0100806:	75 88                	jne    f0100790 <mon_backtrace+0x1b>

		cprintf("\t\t%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, info.eip_fn_addr);
	}
	
	return 0;
}
f0100808:	b8 00 00 00 00       	mov    $0x0,%eax
f010080d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100810:	5b                   	pop    %ebx
f0100811:	5e                   	pop    %esi
f0100812:	5f                   	pop    %edi
f0100813:	5d                   	pop    %ebp
f0100814:	c3                   	ret    

f0100815 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100815:	55                   	push   %ebp
f0100816:	89 e5                	mov    %esp,%ebp
f0100818:	57                   	push   %edi
f0100819:	56                   	push   %esi
f010081a:	53                   	push   %ebx
f010081b:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010081e:	68 58 1d 10 f0       	push   $0xf0101d58
f0100823:	e8 6d 01 00 00       	call   f0100995 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100828:	c7 04 24 7c 1d 10 f0 	movl   $0xf0101d7c,(%esp)
f010082f:	e8 61 01 00 00       	call   f0100995 <cprintf>
f0100834:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100837:	83 ec 0c             	sub    $0xc,%esp
f010083a:	68 10 1c 10 f0       	push   $0xf0101c10
f010083f:	e8 64 09 00 00       	call   f01011a8 <readline>
f0100844:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100846:	83 c4 10             	add    $0x10,%esp
f0100849:	85 c0                	test   %eax,%eax
f010084b:	74 ea                	je     f0100837 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010084d:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100854:	be 00 00 00 00       	mov    $0x0,%esi
f0100859:	eb 0a                	jmp    f0100865 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010085b:	c6 03 00             	movb   $0x0,(%ebx)
f010085e:	89 f7                	mov    %esi,%edi
f0100860:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100863:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100865:	0f b6 03             	movzbl (%ebx),%eax
f0100868:	84 c0                	test   %al,%al
f010086a:	74 63                	je     f01008cf <monitor+0xba>
f010086c:	83 ec 08             	sub    $0x8,%esp
f010086f:	0f be c0             	movsbl %al,%eax
f0100872:	50                   	push   %eax
f0100873:	68 14 1c 10 f0       	push   $0xf0101c14
f0100878:	e8 45 0b 00 00       	call   f01013c2 <strchr>
f010087d:	83 c4 10             	add    $0x10,%esp
f0100880:	85 c0                	test   %eax,%eax
f0100882:	75 d7                	jne    f010085b <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100884:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100887:	74 46                	je     f01008cf <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100889:	83 fe 0f             	cmp    $0xf,%esi
f010088c:	75 14                	jne    f01008a2 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010088e:	83 ec 08             	sub    $0x8,%esp
f0100891:	6a 10                	push   $0x10
f0100893:	68 19 1c 10 f0       	push   $0xf0101c19
f0100898:	e8 f8 00 00 00       	call   f0100995 <cprintf>
f010089d:	83 c4 10             	add    $0x10,%esp
f01008a0:	eb 95                	jmp    f0100837 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01008a2:	8d 7e 01             	lea    0x1(%esi),%edi
f01008a5:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008a9:	eb 03                	jmp    f01008ae <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008ab:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008ae:	0f b6 03             	movzbl (%ebx),%eax
f01008b1:	84 c0                	test   %al,%al
f01008b3:	74 ae                	je     f0100863 <monitor+0x4e>
f01008b5:	83 ec 08             	sub    $0x8,%esp
f01008b8:	0f be c0             	movsbl %al,%eax
f01008bb:	50                   	push   %eax
f01008bc:	68 14 1c 10 f0       	push   $0xf0101c14
f01008c1:	e8 fc 0a 00 00       	call   f01013c2 <strchr>
f01008c6:	83 c4 10             	add    $0x10,%esp
f01008c9:	85 c0                	test   %eax,%eax
f01008cb:	74 de                	je     f01008ab <monitor+0x96>
f01008cd:	eb 94                	jmp    f0100863 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008cf:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008d6:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008d7:	85 f6                	test   %esi,%esi
f01008d9:	0f 84 58 ff ff ff    	je     f0100837 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008df:	83 ec 08             	sub    $0x8,%esp
f01008e2:	68 9e 1b 10 f0       	push   $0xf0101b9e
f01008e7:	ff 75 a8             	pushl  -0x58(%ebp)
f01008ea:	e8 75 0a 00 00       	call   f0101364 <strcmp>
f01008ef:	83 c4 10             	add    $0x10,%esp
f01008f2:	85 c0                	test   %eax,%eax
f01008f4:	74 1e                	je     f0100914 <monitor+0xff>
f01008f6:	83 ec 08             	sub    $0x8,%esp
f01008f9:	68 ac 1b 10 f0       	push   $0xf0101bac
f01008fe:	ff 75 a8             	pushl  -0x58(%ebp)
f0100901:	e8 5e 0a 00 00       	call   f0101364 <strcmp>
f0100906:	83 c4 10             	add    $0x10,%esp
f0100909:	85 c0                	test   %eax,%eax
f010090b:	75 2f                	jne    f010093c <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010090d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100912:	eb 05                	jmp    f0100919 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100914:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100919:	83 ec 04             	sub    $0x4,%esp
f010091c:	8d 14 00             	lea    (%eax,%eax,1),%edx
f010091f:	01 d0                	add    %edx,%eax
f0100921:	ff 75 08             	pushl  0x8(%ebp)
f0100924:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100927:	51                   	push   %ecx
f0100928:	56                   	push   %esi
f0100929:	ff 14 85 ac 1d 10 f0 	call   *-0xfefe254(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100930:	83 c4 10             	add    $0x10,%esp
f0100933:	85 c0                	test   %eax,%eax
f0100935:	78 1d                	js     f0100954 <monitor+0x13f>
f0100937:	e9 fb fe ff ff       	jmp    f0100837 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010093c:	83 ec 08             	sub    $0x8,%esp
f010093f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100942:	68 36 1c 10 f0       	push   $0xf0101c36
f0100947:	e8 49 00 00 00       	call   f0100995 <cprintf>
f010094c:	83 c4 10             	add    $0x10,%esp
f010094f:	e9 e3 fe ff ff       	jmp    f0100837 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100954:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100957:	5b                   	pop    %ebx
f0100958:	5e                   	pop    %esi
f0100959:	5f                   	pop    %edi
f010095a:	5d                   	pop    %ebp
f010095b:	c3                   	ret    

f010095c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010095c:	55                   	push   %ebp
f010095d:	89 e5                	mov    %esp,%ebp
f010095f:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100962:	ff 75 08             	pushl  0x8(%ebp)
f0100965:	e8 f1 fc ff ff       	call   f010065b <cputchar>
	*cnt++;
}
f010096a:	83 c4 10             	add    $0x10,%esp
f010096d:	c9                   	leave  
f010096e:	c3                   	ret    

f010096f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010096f:	55                   	push   %ebp
f0100970:	89 e5                	mov    %esp,%ebp
f0100972:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100975:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010097c:	ff 75 0c             	pushl  0xc(%ebp)
f010097f:	ff 75 08             	pushl  0x8(%ebp)
f0100982:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100985:	50                   	push   %eax
f0100986:	68 5c 09 10 f0       	push   $0xf010095c
f010098b:	e8 03 04 00 00       	call   f0100d93 <vprintfmt>
	return cnt;
}
f0100990:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100993:	c9                   	leave  
f0100994:	c3                   	ret    

f0100995 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100995:	55                   	push   %ebp
f0100996:	89 e5                	mov    %esp,%ebp
f0100998:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010099b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010099e:	50                   	push   %eax
f010099f:	ff 75 08             	pushl  0x8(%ebp)
f01009a2:	e8 c8 ff ff ff       	call   f010096f <vcprintf>
	va_end(ap);

	return cnt;
}
f01009a7:	c9                   	leave  
f01009a8:	c3                   	ret    

f01009a9 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009a9:	55                   	push   %ebp
f01009aa:	89 e5                	mov    %esp,%ebp
f01009ac:	57                   	push   %edi
f01009ad:	56                   	push   %esi
f01009ae:	53                   	push   %ebx
f01009af:	83 ec 14             	sub    $0x14,%esp
f01009b2:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009b5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01009b8:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01009bb:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009be:	8b 1a                	mov    (%edx),%ebx
f01009c0:	8b 01                	mov    (%ecx),%eax
f01009c2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009c5:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009cc:	eb 7f                	jmp    f0100a4d <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01009ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009d1:	01 d8                	add    %ebx,%eax
f01009d3:	89 c6                	mov    %eax,%esi
f01009d5:	c1 ee 1f             	shr    $0x1f,%esi
f01009d8:	01 c6                	add    %eax,%esi
f01009da:	d1 fe                	sar    %esi
f01009dc:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009df:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009e2:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009e5:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009e7:	eb 03                	jmp    f01009ec <stab_binsearch+0x43>
			m--;
f01009e9:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009ec:	39 c3                	cmp    %eax,%ebx
f01009ee:	7f 0d                	jg     f01009fd <stab_binsearch+0x54>
f01009f0:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01009f4:	83 ea 0c             	sub    $0xc,%edx
f01009f7:	39 f9                	cmp    %edi,%ecx
f01009f9:	75 ee                	jne    f01009e9 <stab_binsearch+0x40>
f01009fb:	eb 05                	jmp    f0100a02 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009fd:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100a00:	eb 4b                	jmp    f0100a4d <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a02:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a05:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a08:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a0c:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a0f:	76 11                	jbe    f0100a22 <stab_binsearch+0x79>
			*region_left = m;
f0100a11:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a14:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a16:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a19:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a20:	eb 2b                	jmp    f0100a4d <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a22:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a25:	73 14                	jae    f0100a3b <stab_binsearch+0x92>
			*region_right = m - 1;
f0100a27:	83 e8 01             	sub    $0x1,%eax
f0100a2a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a2d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a30:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a32:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a39:	eb 12                	jmp    f0100a4d <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a3b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a3e:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a40:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a44:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a46:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a4d:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a50:	0f 8e 78 ff ff ff    	jle    f01009ce <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a56:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a5a:	75 0f                	jne    f0100a6b <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a5c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a5f:	8b 00                	mov    (%eax),%eax
f0100a61:	83 e8 01             	sub    $0x1,%eax
f0100a64:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a67:	89 06                	mov    %eax,(%esi)
f0100a69:	eb 2c                	jmp    f0100a97 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a6b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a6e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a70:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a73:	8b 0e                	mov    (%esi),%ecx
f0100a75:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a78:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a7b:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a7e:	eb 03                	jmp    f0100a83 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a80:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a83:	39 c8                	cmp    %ecx,%eax
f0100a85:	7e 0b                	jle    f0100a92 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a87:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a8b:	83 ea 0c             	sub    $0xc,%edx
f0100a8e:	39 df                	cmp    %ebx,%edi
f0100a90:	75 ee                	jne    f0100a80 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a92:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a95:	89 06                	mov    %eax,(%esi)
	}
}
f0100a97:	83 c4 14             	add    $0x14,%esp
f0100a9a:	5b                   	pop    %ebx
f0100a9b:	5e                   	pop    %esi
f0100a9c:	5f                   	pop    %edi
f0100a9d:	5d                   	pop    %ebp
f0100a9e:	c3                   	ret    

f0100a9f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a9f:	55                   	push   %ebp
f0100aa0:	89 e5                	mov    %esp,%ebp
f0100aa2:	57                   	push   %edi
f0100aa3:	56                   	push   %esi
f0100aa4:	53                   	push   %ebx
f0100aa5:	83 ec 1c             	sub    $0x1c,%esp
f0100aa8:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100aab:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100aae:	c7 06 bc 1d 10 f0    	movl   $0xf0101dbc,(%esi)
	info->eip_line = 0;
f0100ab4:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100abb:	c7 46 08 bc 1d 10 f0 	movl   $0xf0101dbc,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100ac2:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100ac9:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100acc:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ad3:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100ad9:	76 11                	jbe    f0100aec <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100adb:	b8 6b 72 10 f0       	mov    $0xf010726b,%eax
f0100ae0:	3d 55 59 10 f0       	cmp    $0xf0105955,%eax
f0100ae5:	77 19                	ja     f0100b00 <debuginfo_eip+0x61>
f0100ae7:	e9 62 01 00 00       	jmp    f0100c4e <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100aec:	83 ec 04             	sub    $0x4,%esp
f0100aef:	68 c6 1d 10 f0       	push   $0xf0101dc6
f0100af4:	6a 7f                	push   $0x7f
f0100af6:	68 d3 1d 10 f0       	push   $0xf0101dd3
f0100afb:	e8 e6 f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b00:	80 3d 6a 72 10 f0 00 	cmpb   $0x0,0xf010726a
f0100b07:	0f 85 48 01 00 00    	jne    f0100c55 <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b0d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b14:	b8 54 59 10 f0       	mov    $0xf0105954,%eax
f0100b19:	2d f4 1f 10 f0       	sub    $0xf0101ff4,%eax
f0100b1e:	c1 f8 02             	sar    $0x2,%eax
f0100b21:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b27:	83 e8 01             	sub    $0x1,%eax
f0100b2a:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b2d:	83 ec 08             	sub    $0x8,%esp
f0100b30:	57                   	push   %edi
f0100b31:	6a 64                	push   $0x64
f0100b33:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b36:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b39:	b8 f4 1f 10 f0       	mov    $0xf0101ff4,%eax
f0100b3e:	e8 66 fe ff ff       	call   f01009a9 <stab_binsearch>
	if (lfile == 0)
f0100b43:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b46:	83 c4 10             	add    $0x10,%esp
f0100b49:	85 c0                	test   %eax,%eax
f0100b4b:	0f 84 0b 01 00 00    	je     f0100c5c <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b51:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b54:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b57:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b5a:	83 ec 08             	sub    $0x8,%esp
f0100b5d:	57                   	push   %edi
f0100b5e:	6a 24                	push   $0x24
f0100b60:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b63:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b66:	b8 f4 1f 10 f0       	mov    $0xf0101ff4,%eax
f0100b6b:	e8 39 fe ff ff       	call   f01009a9 <stab_binsearch>

	if (lfun <= rfun) {
f0100b70:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100b73:	83 c4 10             	add    $0x10,%esp
f0100b76:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100b79:	7f 31                	jg     f0100bac <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b7b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b7e:	c1 e0 02             	shl    $0x2,%eax
f0100b81:	8d 90 f4 1f 10 f0    	lea    -0xfefe00c(%eax),%edx
f0100b87:	8b 88 f4 1f 10 f0    	mov    -0xfefe00c(%eax),%ecx
f0100b8d:	b8 6b 72 10 f0       	mov    $0xf010726b,%eax
f0100b92:	2d 55 59 10 f0       	sub    $0xf0105955,%eax
f0100b97:	39 c1                	cmp    %eax,%ecx
f0100b99:	73 09                	jae    f0100ba4 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b9b:	81 c1 55 59 10 f0    	add    $0xf0105955,%ecx
f0100ba1:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100ba4:	8b 42 08             	mov    0x8(%edx),%eax
f0100ba7:	89 46 10             	mov    %eax,0x10(%esi)
f0100baa:	eb 06                	jmp    f0100bb2 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bac:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100baf:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bb2:	83 ec 08             	sub    $0x8,%esp
f0100bb5:	6a 3a                	push   $0x3a
f0100bb7:	ff 76 08             	pushl  0x8(%esi)
f0100bba:	e8 24 08 00 00       	call   f01013e3 <strfind>
f0100bbf:	2b 46 08             	sub    0x8(%esi),%eax
f0100bc2:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bc5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100bc8:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100bcb:	8d 04 85 f4 1f 10 f0 	lea    -0xfefe00c(,%eax,4),%eax
f0100bd2:	83 c4 10             	add    $0x10,%esp
f0100bd5:	eb 06                	jmp    f0100bdd <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100bd7:	83 eb 01             	sub    $0x1,%ebx
f0100bda:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bdd:	39 fb                	cmp    %edi,%ebx
f0100bdf:	7c 34                	jl     f0100c15 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0100be1:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100be5:	80 fa 84             	cmp    $0x84,%dl
f0100be8:	74 0b                	je     f0100bf5 <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100bea:	80 fa 64             	cmp    $0x64,%dl
f0100bed:	75 e8                	jne    f0100bd7 <debuginfo_eip+0x138>
f0100bef:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100bf3:	74 e2                	je     f0100bd7 <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100bf5:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100bf8:	8b 14 85 f4 1f 10 f0 	mov    -0xfefe00c(,%eax,4),%edx
f0100bff:	b8 6b 72 10 f0       	mov    $0xf010726b,%eax
f0100c04:	2d 55 59 10 f0       	sub    $0xf0105955,%eax
f0100c09:	39 c2                	cmp    %eax,%edx
f0100c0b:	73 08                	jae    f0100c15 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c0d:	81 c2 55 59 10 f0    	add    $0xf0105955,%edx
f0100c13:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c15:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100c18:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c1b:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c20:	39 cb                	cmp    %ecx,%ebx
f0100c22:	7d 44                	jge    f0100c68 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0100c24:	8d 53 01             	lea    0x1(%ebx),%edx
f0100c27:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c2a:	8d 04 85 f4 1f 10 f0 	lea    -0xfefe00c(,%eax,4),%eax
f0100c31:	eb 07                	jmp    f0100c3a <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c33:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c37:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c3a:	39 ca                	cmp    %ecx,%edx
f0100c3c:	74 25                	je     f0100c63 <debuginfo_eip+0x1c4>
f0100c3e:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c41:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100c45:	74 ec                	je     f0100c33 <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c47:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c4c:	eb 1a                	jmp    f0100c68 <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c4e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c53:	eb 13                	jmp    f0100c68 <debuginfo_eip+0x1c9>
f0100c55:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c5a:	eb 0c                	jmp    f0100c68 <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c61:	eb 05                	jmp    f0100c68 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c63:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c68:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c6b:	5b                   	pop    %ebx
f0100c6c:	5e                   	pop    %esi
f0100c6d:	5f                   	pop    %edi
f0100c6e:	5d                   	pop    %ebp
f0100c6f:	c3                   	ret    

f0100c70 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c70:	55                   	push   %ebp
f0100c71:	89 e5                	mov    %esp,%ebp
f0100c73:	57                   	push   %edi
f0100c74:	56                   	push   %esi
f0100c75:	53                   	push   %ebx
f0100c76:	83 ec 1c             	sub    $0x1c,%esp
f0100c79:	89 c7                	mov    %eax,%edi
f0100c7b:	89 d6                	mov    %edx,%esi
f0100c7d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c80:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c83:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c86:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c89:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100c8c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c91:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100c94:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100c97:	39 d3                	cmp    %edx,%ebx
f0100c99:	72 05                	jb     f0100ca0 <printnum+0x30>
f0100c9b:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100c9e:	77 45                	ja     f0100ce5 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ca0:	83 ec 0c             	sub    $0xc,%esp
f0100ca3:	ff 75 18             	pushl  0x18(%ebp)
f0100ca6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ca9:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100cac:	53                   	push   %ebx
f0100cad:	ff 75 10             	pushl  0x10(%ebp)
f0100cb0:	83 ec 08             	sub    $0x8,%esp
f0100cb3:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100cb6:	ff 75 e0             	pushl  -0x20(%ebp)
f0100cb9:	ff 75 dc             	pushl  -0x24(%ebp)
f0100cbc:	ff 75 d8             	pushl  -0x28(%ebp)
f0100cbf:	e8 4c 09 00 00       	call   f0101610 <__udivdi3>
f0100cc4:	83 c4 18             	add    $0x18,%esp
f0100cc7:	52                   	push   %edx
f0100cc8:	50                   	push   %eax
f0100cc9:	89 f2                	mov    %esi,%edx
f0100ccb:	89 f8                	mov    %edi,%eax
f0100ccd:	e8 9e ff ff ff       	call   f0100c70 <printnum>
f0100cd2:	83 c4 20             	add    $0x20,%esp
f0100cd5:	eb 18                	jmp    f0100cef <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100cd7:	83 ec 08             	sub    $0x8,%esp
f0100cda:	56                   	push   %esi
f0100cdb:	ff 75 18             	pushl  0x18(%ebp)
f0100cde:	ff d7                	call   *%edi
f0100ce0:	83 c4 10             	add    $0x10,%esp
f0100ce3:	eb 03                	jmp    f0100ce8 <printnum+0x78>
f0100ce5:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100ce8:	83 eb 01             	sub    $0x1,%ebx
f0100ceb:	85 db                	test   %ebx,%ebx
f0100ced:	7f e8                	jg     f0100cd7 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100cef:	83 ec 08             	sub    $0x8,%esp
f0100cf2:	56                   	push   %esi
f0100cf3:	83 ec 04             	sub    $0x4,%esp
f0100cf6:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100cf9:	ff 75 e0             	pushl  -0x20(%ebp)
f0100cfc:	ff 75 dc             	pushl  -0x24(%ebp)
f0100cff:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d02:	e8 39 0a 00 00       	call   f0101740 <__umoddi3>
f0100d07:	83 c4 14             	add    $0x14,%esp
f0100d0a:	0f be 80 e1 1d 10 f0 	movsbl -0xfefe21f(%eax),%eax
f0100d11:	50                   	push   %eax
f0100d12:	ff d7                	call   *%edi
}
f0100d14:	83 c4 10             	add    $0x10,%esp
f0100d17:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d1a:	5b                   	pop    %ebx
f0100d1b:	5e                   	pop    %esi
f0100d1c:	5f                   	pop    %edi
f0100d1d:	5d                   	pop    %ebp
f0100d1e:	c3                   	ret    

f0100d1f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d1f:	55                   	push   %ebp
f0100d20:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d22:	83 fa 01             	cmp    $0x1,%edx
f0100d25:	7e 0e                	jle    f0100d35 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d27:	8b 10                	mov    (%eax),%edx
f0100d29:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d2c:	89 08                	mov    %ecx,(%eax)
f0100d2e:	8b 02                	mov    (%edx),%eax
f0100d30:	8b 52 04             	mov    0x4(%edx),%edx
f0100d33:	eb 22                	jmp    f0100d57 <getuint+0x38>
	else if (lflag)
f0100d35:	85 d2                	test   %edx,%edx
f0100d37:	74 10                	je     f0100d49 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d39:	8b 10                	mov    (%eax),%edx
f0100d3b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d3e:	89 08                	mov    %ecx,(%eax)
f0100d40:	8b 02                	mov    (%edx),%eax
f0100d42:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d47:	eb 0e                	jmp    f0100d57 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d49:	8b 10                	mov    (%eax),%edx
f0100d4b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d4e:	89 08                	mov    %ecx,(%eax)
f0100d50:	8b 02                	mov    (%edx),%eax
f0100d52:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d57:	5d                   	pop    %ebp
f0100d58:	c3                   	ret    

f0100d59 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d59:	55                   	push   %ebp
f0100d5a:	89 e5                	mov    %esp,%ebp
f0100d5c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d5f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d63:	8b 10                	mov    (%eax),%edx
f0100d65:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d68:	73 0a                	jae    f0100d74 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d6a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d6d:	89 08                	mov    %ecx,(%eax)
f0100d6f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d72:	88 02                	mov    %al,(%edx)
}
f0100d74:	5d                   	pop    %ebp
f0100d75:	c3                   	ret    

f0100d76 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d76:	55                   	push   %ebp
f0100d77:	89 e5                	mov    %esp,%ebp
f0100d79:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d7c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d7f:	50                   	push   %eax
f0100d80:	ff 75 10             	pushl  0x10(%ebp)
f0100d83:	ff 75 0c             	pushl  0xc(%ebp)
f0100d86:	ff 75 08             	pushl  0x8(%ebp)
f0100d89:	e8 05 00 00 00       	call   f0100d93 <vprintfmt>
	va_end(ap);
}
f0100d8e:	83 c4 10             	add    $0x10,%esp
f0100d91:	c9                   	leave  
f0100d92:	c3                   	ret    

f0100d93 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d93:	55                   	push   %ebp
f0100d94:	89 e5                	mov    %esp,%ebp
f0100d96:	57                   	push   %edi
f0100d97:	56                   	push   %esi
f0100d98:	53                   	push   %ebx
f0100d99:	83 ec 2c             	sub    $0x2c,%esp
f0100d9c:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d9f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100da2:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100da5:	eb 12                	jmp    f0100db9 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100da7:	85 c0                	test   %eax,%eax
f0100da9:	0f 84 89 03 00 00    	je     f0101138 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0100daf:	83 ec 08             	sub    $0x8,%esp
f0100db2:	53                   	push   %ebx
f0100db3:	50                   	push   %eax
f0100db4:	ff d6                	call   *%esi
f0100db6:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100db9:	83 c7 01             	add    $0x1,%edi
f0100dbc:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100dc0:	83 f8 25             	cmp    $0x25,%eax
f0100dc3:	75 e2                	jne    f0100da7 <vprintfmt+0x14>
f0100dc5:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100dc9:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100dd0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100dd7:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100dde:	ba 00 00 00 00       	mov    $0x0,%edx
f0100de3:	eb 07                	jmp    f0100dec <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100de5:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100de8:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dec:	8d 47 01             	lea    0x1(%edi),%eax
f0100def:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100df2:	0f b6 07             	movzbl (%edi),%eax
f0100df5:	0f b6 c8             	movzbl %al,%ecx
f0100df8:	83 e8 23             	sub    $0x23,%eax
f0100dfb:	3c 55                	cmp    $0x55,%al
f0100dfd:	0f 87 1a 03 00 00    	ja     f010111d <vprintfmt+0x38a>
f0100e03:	0f b6 c0             	movzbl %al,%eax
f0100e06:	ff 24 85 70 1e 10 f0 	jmp    *-0xfefe190(,%eax,4)
f0100e0d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e10:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e14:	eb d6                	jmp    f0100dec <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e16:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e19:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e1e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e21:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100e24:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100e28:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100e2b:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100e2e:	83 fa 09             	cmp    $0x9,%edx
f0100e31:	77 39                	ja     f0100e6c <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e33:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e36:	eb e9                	jmp    f0100e21 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e38:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e3b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e3e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e41:	8b 00                	mov    (%eax),%eax
f0100e43:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e46:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e49:	eb 27                	jmp    f0100e72 <vprintfmt+0xdf>
f0100e4b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e4e:	85 c0                	test   %eax,%eax
f0100e50:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e55:	0f 49 c8             	cmovns %eax,%ecx
f0100e58:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e5b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e5e:	eb 8c                	jmp    f0100dec <vprintfmt+0x59>
f0100e60:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e63:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e6a:	eb 80                	jmp    f0100dec <vprintfmt+0x59>
f0100e6c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100e6f:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100e72:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e76:	0f 89 70 ff ff ff    	jns    f0100dec <vprintfmt+0x59>
				width = precision, precision = -1;
f0100e7c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100e7f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e82:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e89:	e9 5e ff ff ff       	jmp    f0100dec <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e8e:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e91:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e94:	e9 53 ff ff ff       	jmp    f0100dec <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e99:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e9c:	8d 50 04             	lea    0x4(%eax),%edx
f0100e9f:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ea2:	83 ec 08             	sub    $0x8,%esp
f0100ea5:	53                   	push   %ebx
f0100ea6:	ff 30                	pushl  (%eax)
f0100ea8:	ff d6                	call   *%esi
			break;
f0100eaa:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ead:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100eb0:	e9 04 ff ff ff       	jmp    f0100db9 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100eb5:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eb8:	8d 50 04             	lea    0x4(%eax),%edx
f0100ebb:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ebe:	8b 00                	mov    (%eax),%eax
f0100ec0:	99                   	cltd   
f0100ec1:	31 d0                	xor    %edx,%eax
f0100ec3:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100ec5:	83 f8 06             	cmp    $0x6,%eax
f0100ec8:	7f 0b                	jg     f0100ed5 <vprintfmt+0x142>
f0100eca:	8b 14 85 c8 1f 10 f0 	mov    -0xfefe038(,%eax,4),%edx
f0100ed1:	85 d2                	test   %edx,%edx
f0100ed3:	75 18                	jne    f0100eed <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0100ed5:	50                   	push   %eax
f0100ed6:	68 f9 1d 10 f0       	push   $0xf0101df9
f0100edb:	53                   	push   %ebx
f0100edc:	56                   	push   %esi
f0100edd:	e8 94 fe ff ff       	call   f0100d76 <printfmt>
f0100ee2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100ee8:	e9 cc fe ff ff       	jmp    f0100db9 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100eed:	52                   	push   %edx
f0100eee:	68 02 1e 10 f0       	push   $0xf0101e02
f0100ef3:	53                   	push   %ebx
f0100ef4:	56                   	push   %esi
f0100ef5:	e8 7c fe ff ff       	call   f0100d76 <printfmt>
f0100efa:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100efd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f00:	e9 b4 fe ff ff       	jmp    f0100db9 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f05:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f08:	8d 50 04             	lea    0x4(%eax),%edx
f0100f0b:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f0e:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100f10:	85 ff                	test   %edi,%edi
f0100f12:	b8 f2 1d 10 f0       	mov    $0xf0101df2,%eax
f0100f17:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100f1a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f1e:	0f 8e 94 00 00 00    	jle    f0100fb8 <vprintfmt+0x225>
f0100f24:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f28:	0f 84 98 00 00 00    	je     f0100fc6 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f2e:	83 ec 08             	sub    $0x8,%esp
f0100f31:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f34:	57                   	push   %edi
f0100f35:	e8 5f 03 00 00       	call   f0101299 <strnlen>
f0100f3a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f3d:	29 c1                	sub    %eax,%ecx
f0100f3f:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100f42:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100f45:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f49:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f4c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f4f:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f51:	eb 0f                	jmp    f0100f62 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0100f53:	83 ec 08             	sub    $0x8,%esp
f0100f56:	53                   	push   %ebx
f0100f57:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f5a:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f5c:	83 ef 01             	sub    $0x1,%edi
f0100f5f:	83 c4 10             	add    $0x10,%esp
f0100f62:	85 ff                	test   %edi,%edi
f0100f64:	7f ed                	jg     f0100f53 <vprintfmt+0x1c0>
f0100f66:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f69:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100f6c:	85 c9                	test   %ecx,%ecx
f0100f6e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f73:	0f 49 c1             	cmovns %ecx,%eax
f0100f76:	29 c1                	sub    %eax,%ecx
f0100f78:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f7b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f7e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f81:	89 cb                	mov    %ecx,%ebx
f0100f83:	eb 4d                	jmp    f0100fd2 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f85:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f89:	74 1b                	je     f0100fa6 <vprintfmt+0x213>
f0100f8b:	0f be c0             	movsbl %al,%eax
f0100f8e:	83 e8 20             	sub    $0x20,%eax
f0100f91:	83 f8 5e             	cmp    $0x5e,%eax
f0100f94:	76 10                	jbe    f0100fa6 <vprintfmt+0x213>
					putch('?', putdat);
f0100f96:	83 ec 08             	sub    $0x8,%esp
f0100f99:	ff 75 0c             	pushl  0xc(%ebp)
f0100f9c:	6a 3f                	push   $0x3f
f0100f9e:	ff 55 08             	call   *0x8(%ebp)
f0100fa1:	83 c4 10             	add    $0x10,%esp
f0100fa4:	eb 0d                	jmp    f0100fb3 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0100fa6:	83 ec 08             	sub    $0x8,%esp
f0100fa9:	ff 75 0c             	pushl  0xc(%ebp)
f0100fac:	52                   	push   %edx
f0100fad:	ff 55 08             	call   *0x8(%ebp)
f0100fb0:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fb3:	83 eb 01             	sub    $0x1,%ebx
f0100fb6:	eb 1a                	jmp    f0100fd2 <vprintfmt+0x23f>
f0100fb8:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fbb:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fbe:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fc1:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100fc4:	eb 0c                	jmp    f0100fd2 <vprintfmt+0x23f>
f0100fc6:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fc9:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fcc:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fcf:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100fd2:	83 c7 01             	add    $0x1,%edi
f0100fd5:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100fd9:	0f be d0             	movsbl %al,%edx
f0100fdc:	85 d2                	test   %edx,%edx
f0100fde:	74 23                	je     f0101003 <vprintfmt+0x270>
f0100fe0:	85 f6                	test   %esi,%esi
f0100fe2:	78 a1                	js     f0100f85 <vprintfmt+0x1f2>
f0100fe4:	83 ee 01             	sub    $0x1,%esi
f0100fe7:	79 9c                	jns    f0100f85 <vprintfmt+0x1f2>
f0100fe9:	89 df                	mov    %ebx,%edi
f0100feb:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fee:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ff1:	eb 18                	jmp    f010100b <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100ff3:	83 ec 08             	sub    $0x8,%esp
f0100ff6:	53                   	push   %ebx
f0100ff7:	6a 20                	push   $0x20
f0100ff9:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100ffb:	83 ef 01             	sub    $0x1,%edi
f0100ffe:	83 c4 10             	add    $0x10,%esp
f0101001:	eb 08                	jmp    f010100b <vprintfmt+0x278>
f0101003:	89 df                	mov    %ebx,%edi
f0101005:	8b 75 08             	mov    0x8(%ebp),%esi
f0101008:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010100b:	85 ff                	test   %edi,%edi
f010100d:	7f e4                	jg     f0100ff3 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010100f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101012:	e9 a2 fd ff ff       	jmp    f0100db9 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101017:	83 fa 01             	cmp    $0x1,%edx
f010101a:	7e 16                	jle    f0101032 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f010101c:	8b 45 14             	mov    0x14(%ebp),%eax
f010101f:	8d 50 08             	lea    0x8(%eax),%edx
f0101022:	89 55 14             	mov    %edx,0x14(%ebp)
f0101025:	8b 50 04             	mov    0x4(%eax),%edx
f0101028:	8b 00                	mov    (%eax),%eax
f010102a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010102d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101030:	eb 32                	jmp    f0101064 <vprintfmt+0x2d1>
	else if (lflag)
f0101032:	85 d2                	test   %edx,%edx
f0101034:	74 18                	je     f010104e <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0101036:	8b 45 14             	mov    0x14(%ebp),%eax
f0101039:	8d 50 04             	lea    0x4(%eax),%edx
f010103c:	89 55 14             	mov    %edx,0x14(%ebp)
f010103f:	8b 00                	mov    (%eax),%eax
f0101041:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101044:	89 c1                	mov    %eax,%ecx
f0101046:	c1 f9 1f             	sar    $0x1f,%ecx
f0101049:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010104c:	eb 16                	jmp    f0101064 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f010104e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101051:	8d 50 04             	lea    0x4(%eax),%edx
f0101054:	89 55 14             	mov    %edx,0x14(%ebp)
f0101057:	8b 00                	mov    (%eax),%eax
f0101059:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010105c:	89 c1                	mov    %eax,%ecx
f010105e:	c1 f9 1f             	sar    $0x1f,%ecx
f0101061:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101064:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101067:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010106a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010106f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101073:	79 74                	jns    f01010e9 <vprintfmt+0x356>
				putch('-', putdat);
f0101075:	83 ec 08             	sub    $0x8,%esp
f0101078:	53                   	push   %ebx
f0101079:	6a 2d                	push   $0x2d
f010107b:	ff d6                	call   *%esi
				num = -(long long) num;
f010107d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101080:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101083:	f7 d8                	neg    %eax
f0101085:	83 d2 00             	adc    $0x0,%edx
f0101088:	f7 da                	neg    %edx
f010108a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010108d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101092:	eb 55                	jmp    f01010e9 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101094:	8d 45 14             	lea    0x14(%ebp),%eax
f0101097:	e8 83 fc ff ff       	call   f0100d1f <getuint>
			base = 10;
f010109c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010a1:	eb 46                	jmp    f01010e9 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code. // GToad L1-8
			num = getuint(&ap, lflag);
f01010a3:	8d 45 14             	lea    0x14(%ebp),%eax
f01010a6:	e8 74 fc ff ff       	call   f0100d1f <getuint>
			base = 8;
f01010ab:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01010b0:	eb 37                	jmp    f01010e9 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f01010b2:	83 ec 08             	sub    $0x8,%esp
f01010b5:	53                   	push   %ebx
f01010b6:	6a 30                	push   $0x30
f01010b8:	ff d6                	call   *%esi
			putch('x', putdat);
f01010ba:	83 c4 08             	add    $0x8,%esp
f01010bd:	53                   	push   %ebx
f01010be:	6a 78                	push   $0x78
f01010c0:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01010c5:	8d 50 04             	lea    0x4(%eax),%edx
f01010c8:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01010cb:	8b 00                	mov    (%eax),%eax
f01010cd:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01010d2:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01010d5:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01010da:	eb 0d                	jmp    f01010e9 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01010dc:	8d 45 14             	lea    0x14(%ebp),%eax
f01010df:	e8 3b fc ff ff       	call   f0100d1f <getuint>
			base = 16;
f01010e4:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01010e9:	83 ec 0c             	sub    $0xc,%esp
f01010ec:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01010f0:	57                   	push   %edi
f01010f1:	ff 75 e0             	pushl  -0x20(%ebp)
f01010f4:	51                   	push   %ecx
f01010f5:	52                   	push   %edx
f01010f6:	50                   	push   %eax
f01010f7:	89 da                	mov    %ebx,%edx
f01010f9:	89 f0                	mov    %esi,%eax
f01010fb:	e8 70 fb ff ff       	call   f0100c70 <printnum>
			break;
f0101100:	83 c4 20             	add    $0x20,%esp
f0101103:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101106:	e9 ae fc ff ff       	jmp    f0100db9 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010110b:	83 ec 08             	sub    $0x8,%esp
f010110e:	53                   	push   %ebx
f010110f:	51                   	push   %ecx
f0101110:	ff d6                	call   *%esi
			break;
f0101112:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101115:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101118:	e9 9c fc ff ff       	jmp    f0100db9 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010111d:	83 ec 08             	sub    $0x8,%esp
f0101120:	53                   	push   %ebx
f0101121:	6a 25                	push   $0x25
f0101123:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101125:	83 c4 10             	add    $0x10,%esp
f0101128:	eb 03                	jmp    f010112d <vprintfmt+0x39a>
f010112a:	83 ef 01             	sub    $0x1,%edi
f010112d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101131:	75 f7                	jne    f010112a <vprintfmt+0x397>
f0101133:	e9 81 fc ff ff       	jmp    f0100db9 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101138:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010113b:	5b                   	pop    %ebx
f010113c:	5e                   	pop    %esi
f010113d:	5f                   	pop    %edi
f010113e:	5d                   	pop    %ebp
f010113f:	c3                   	ret    

f0101140 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101140:	55                   	push   %ebp
f0101141:	89 e5                	mov    %esp,%ebp
f0101143:	83 ec 18             	sub    $0x18,%esp
f0101146:	8b 45 08             	mov    0x8(%ebp),%eax
f0101149:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010114c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010114f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101153:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101156:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010115d:	85 c0                	test   %eax,%eax
f010115f:	74 26                	je     f0101187 <vsnprintf+0x47>
f0101161:	85 d2                	test   %edx,%edx
f0101163:	7e 22                	jle    f0101187 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101165:	ff 75 14             	pushl  0x14(%ebp)
f0101168:	ff 75 10             	pushl  0x10(%ebp)
f010116b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010116e:	50                   	push   %eax
f010116f:	68 59 0d 10 f0       	push   $0xf0100d59
f0101174:	e8 1a fc ff ff       	call   f0100d93 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101179:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010117c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010117f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101182:	83 c4 10             	add    $0x10,%esp
f0101185:	eb 05                	jmp    f010118c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101187:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010118c:	c9                   	leave  
f010118d:	c3                   	ret    

f010118e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010118e:	55                   	push   %ebp
f010118f:	89 e5                	mov    %esp,%ebp
f0101191:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101194:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101197:	50                   	push   %eax
f0101198:	ff 75 10             	pushl  0x10(%ebp)
f010119b:	ff 75 0c             	pushl  0xc(%ebp)
f010119e:	ff 75 08             	pushl  0x8(%ebp)
f01011a1:	e8 9a ff ff ff       	call   f0101140 <vsnprintf>
	va_end(ap);

	return rc;
}
f01011a6:	c9                   	leave  
f01011a7:	c3                   	ret    

f01011a8 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011a8:	55                   	push   %ebp
f01011a9:	89 e5                	mov    %esp,%ebp
f01011ab:	57                   	push   %edi
f01011ac:	56                   	push   %esi
f01011ad:	53                   	push   %ebx
f01011ae:	83 ec 0c             	sub    $0xc,%esp
f01011b1:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01011b4:	85 c0                	test   %eax,%eax
f01011b6:	74 11                	je     f01011c9 <readline+0x21>
		cprintf("%s", prompt);
f01011b8:	83 ec 08             	sub    $0x8,%esp
f01011bb:	50                   	push   %eax
f01011bc:	68 02 1e 10 f0       	push   $0xf0101e02
f01011c1:	e8 cf f7 ff ff       	call   f0100995 <cprintf>
f01011c6:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01011c9:	83 ec 0c             	sub    $0xc,%esp
f01011cc:	6a 00                	push   $0x0
f01011ce:	e8 a9 f4 ff ff       	call   f010067c <iscons>
f01011d3:	89 c7                	mov    %eax,%edi
f01011d5:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01011d8:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01011dd:	e8 89 f4 ff ff       	call   f010066b <getchar>
f01011e2:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01011e4:	85 c0                	test   %eax,%eax
f01011e6:	79 18                	jns    f0101200 <readline+0x58>
			cprintf("read error: %e\n", c);
f01011e8:	83 ec 08             	sub    $0x8,%esp
f01011eb:	50                   	push   %eax
f01011ec:	68 e4 1f 10 f0       	push   $0xf0101fe4
f01011f1:	e8 9f f7 ff ff       	call   f0100995 <cprintf>
			return NULL;
f01011f6:	83 c4 10             	add    $0x10,%esp
f01011f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01011fe:	eb 79                	jmp    f0101279 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101200:	83 f8 08             	cmp    $0x8,%eax
f0101203:	0f 94 c2             	sete   %dl
f0101206:	83 f8 7f             	cmp    $0x7f,%eax
f0101209:	0f 94 c0             	sete   %al
f010120c:	08 c2                	or     %al,%dl
f010120e:	74 1a                	je     f010122a <readline+0x82>
f0101210:	85 f6                	test   %esi,%esi
f0101212:	7e 16                	jle    f010122a <readline+0x82>
			if (echoing)
f0101214:	85 ff                	test   %edi,%edi
f0101216:	74 0d                	je     f0101225 <readline+0x7d>
				cputchar('\b');
f0101218:	83 ec 0c             	sub    $0xc,%esp
f010121b:	6a 08                	push   $0x8
f010121d:	e8 39 f4 ff ff       	call   f010065b <cputchar>
f0101222:	83 c4 10             	add    $0x10,%esp
			i--;
f0101225:	83 ee 01             	sub    $0x1,%esi
f0101228:	eb b3                	jmp    f01011dd <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010122a:	83 fb 1f             	cmp    $0x1f,%ebx
f010122d:	7e 23                	jle    f0101252 <readline+0xaa>
f010122f:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101235:	7f 1b                	jg     f0101252 <readline+0xaa>
			if (echoing)
f0101237:	85 ff                	test   %edi,%edi
f0101239:	74 0c                	je     f0101247 <readline+0x9f>
				cputchar(c);
f010123b:	83 ec 0c             	sub    $0xc,%esp
f010123e:	53                   	push   %ebx
f010123f:	e8 17 f4 ff ff       	call   f010065b <cputchar>
f0101244:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101247:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f010124d:	8d 76 01             	lea    0x1(%esi),%esi
f0101250:	eb 8b                	jmp    f01011dd <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101252:	83 fb 0a             	cmp    $0xa,%ebx
f0101255:	74 05                	je     f010125c <readline+0xb4>
f0101257:	83 fb 0d             	cmp    $0xd,%ebx
f010125a:	75 81                	jne    f01011dd <readline+0x35>
			if (echoing)
f010125c:	85 ff                	test   %edi,%edi
f010125e:	74 0d                	je     f010126d <readline+0xc5>
				cputchar('\n');
f0101260:	83 ec 0c             	sub    $0xc,%esp
f0101263:	6a 0a                	push   $0xa
f0101265:	e8 f1 f3 ff ff       	call   f010065b <cputchar>
f010126a:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010126d:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f0101274:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101279:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010127c:	5b                   	pop    %ebx
f010127d:	5e                   	pop    %esi
f010127e:	5f                   	pop    %edi
f010127f:	5d                   	pop    %ebp
f0101280:	c3                   	ret    

f0101281 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101281:	55                   	push   %ebp
f0101282:	89 e5                	mov    %esp,%ebp
f0101284:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101287:	b8 00 00 00 00       	mov    $0x0,%eax
f010128c:	eb 03                	jmp    f0101291 <strlen+0x10>
		n++;
f010128e:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101291:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101295:	75 f7                	jne    f010128e <strlen+0xd>
		n++;
	return n;
}
f0101297:	5d                   	pop    %ebp
f0101298:	c3                   	ret    

f0101299 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101299:	55                   	push   %ebp
f010129a:	89 e5                	mov    %esp,%ebp
f010129c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010129f:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012a2:	ba 00 00 00 00       	mov    $0x0,%edx
f01012a7:	eb 03                	jmp    f01012ac <strnlen+0x13>
		n++;
f01012a9:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012ac:	39 c2                	cmp    %eax,%edx
f01012ae:	74 08                	je     f01012b8 <strnlen+0x1f>
f01012b0:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01012b4:	75 f3                	jne    f01012a9 <strnlen+0x10>
f01012b6:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01012b8:	5d                   	pop    %ebp
f01012b9:	c3                   	ret    

f01012ba <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01012ba:	55                   	push   %ebp
f01012bb:	89 e5                	mov    %esp,%ebp
f01012bd:	53                   	push   %ebx
f01012be:	8b 45 08             	mov    0x8(%ebp),%eax
f01012c1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01012c4:	89 c2                	mov    %eax,%edx
f01012c6:	83 c2 01             	add    $0x1,%edx
f01012c9:	83 c1 01             	add    $0x1,%ecx
f01012cc:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01012d0:	88 5a ff             	mov    %bl,-0x1(%edx)
f01012d3:	84 db                	test   %bl,%bl
f01012d5:	75 ef                	jne    f01012c6 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01012d7:	5b                   	pop    %ebx
f01012d8:	5d                   	pop    %ebp
f01012d9:	c3                   	ret    

f01012da <strcat>:

char *
strcat(char *dst, const char *src)
{
f01012da:	55                   	push   %ebp
f01012db:	89 e5                	mov    %esp,%ebp
f01012dd:	53                   	push   %ebx
f01012de:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01012e1:	53                   	push   %ebx
f01012e2:	e8 9a ff ff ff       	call   f0101281 <strlen>
f01012e7:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01012ea:	ff 75 0c             	pushl  0xc(%ebp)
f01012ed:	01 d8                	add    %ebx,%eax
f01012ef:	50                   	push   %eax
f01012f0:	e8 c5 ff ff ff       	call   f01012ba <strcpy>
	return dst;
}
f01012f5:	89 d8                	mov    %ebx,%eax
f01012f7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012fa:	c9                   	leave  
f01012fb:	c3                   	ret    

f01012fc <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01012fc:	55                   	push   %ebp
f01012fd:	89 e5                	mov    %esp,%ebp
f01012ff:	56                   	push   %esi
f0101300:	53                   	push   %ebx
f0101301:	8b 75 08             	mov    0x8(%ebp),%esi
f0101304:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101307:	89 f3                	mov    %esi,%ebx
f0101309:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010130c:	89 f2                	mov    %esi,%edx
f010130e:	eb 0f                	jmp    f010131f <strncpy+0x23>
		*dst++ = *src;
f0101310:	83 c2 01             	add    $0x1,%edx
f0101313:	0f b6 01             	movzbl (%ecx),%eax
f0101316:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101319:	80 39 01             	cmpb   $0x1,(%ecx)
f010131c:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010131f:	39 da                	cmp    %ebx,%edx
f0101321:	75 ed                	jne    f0101310 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101323:	89 f0                	mov    %esi,%eax
f0101325:	5b                   	pop    %ebx
f0101326:	5e                   	pop    %esi
f0101327:	5d                   	pop    %ebp
f0101328:	c3                   	ret    

f0101329 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101329:	55                   	push   %ebp
f010132a:	89 e5                	mov    %esp,%ebp
f010132c:	56                   	push   %esi
f010132d:	53                   	push   %ebx
f010132e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101331:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101334:	8b 55 10             	mov    0x10(%ebp),%edx
f0101337:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101339:	85 d2                	test   %edx,%edx
f010133b:	74 21                	je     f010135e <strlcpy+0x35>
f010133d:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101341:	89 f2                	mov    %esi,%edx
f0101343:	eb 09                	jmp    f010134e <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101345:	83 c2 01             	add    $0x1,%edx
f0101348:	83 c1 01             	add    $0x1,%ecx
f010134b:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010134e:	39 c2                	cmp    %eax,%edx
f0101350:	74 09                	je     f010135b <strlcpy+0x32>
f0101352:	0f b6 19             	movzbl (%ecx),%ebx
f0101355:	84 db                	test   %bl,%bl
f0101357:	75 ec                	jne    f0101345 <strlcpy+0x1c>
f0101359:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010135b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010135e:	29 f0                	sub    %esi,%eax
}
f0101360:	5b                   	pop    %ebx
f0101361:	5e                   	pop    %esi
f0101362:	5d                   	pop    %ebp
f0101363:	c3                   	ret    

f0101364 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101364:	55                   	push   %ebp
f0101365:	89 e5                	mov    %esp,%ebp
f0101367:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010136a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010136d:	eb 06                	jmp    f0101375 <strcmp+0x11>
		p++, q++;
f010136f:	83 c1 01             	add    $0x1,%ecx
f0101372:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101375:	0f b6 01             	movzbl (%ecx),%eax
f0101378:	84 c0                	test   %al,%al
f010137a:	74 04                	je     f0101380 <strcmp+0x1c>
f010137c:	3a 02                	cmp    (%edx),%al
f010137e:	74 ef                	je     f010136f <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101380:	0f b6 c0             	movzbl %al,%eax
f0101383:	0f b6 12             	movzbl (%edx),%edx
f0101386:	29 d0                	sub    %edx,%eax
}
f0101388:	5d                   	pop    %ebp
f0101389:	c3                   	ret    

f010138a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010138a:	55                   	push   %ebp
f010138b:	89 e5                	mov    %esp,%ebp
f010138d:	53                   	push   %ebx
f010138e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101391:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101394:	89 c3                	mov    %eax,%ebx
f0101396:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101399:	eb 06                	jmp    f01013a1 <strncmp+0x17>
		n--, p++, q++;
f010139b:	83 c0 01             	add    $0x1,%eax
f010139e:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013a1:	39 d8                	cmp    %ebx,%eax
f01013a3:	74 15                	je     f01013ba <strncmp+0x30>
f01013a5:	0f b6 08             	movzbl (%eax),%ecx
f01013a8:	84 c9                	test   %cl,%cl
f01013aa:	74 04                	je     f01013b0 <strncmp+0x26>
f01013ac:	3a 0a                	cmp    (%edx),%cl
f01013ae:	74 eb                	je     f010139b <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01013b0:	0f b6 00             	movzbl (%eax),%eax
f01013b3:	0f b6 12             	movzbl (%edx),%edx
f01013b6:	29 d0                	sub    %edx,%eax
f01013b8:	eb 05                	jmp    f01013bf <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01013ba:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01013bf:	5b                   	pop    %ebx
f01013c0:	5d                   	pop    %ebp
f01013c1:	c3                   	ret    

f01013c2 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01013c2:	55                   	push   %ebp
f01013c3:	89 e5                	mov    %esp,%ebp
f01013c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01013c8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013cc:	eb 07                	jmp    f01013d5 <strchr+0x13>
		if (*s == c)
f01013ce:	38 ca                	cmp    %cl,%dl
f01013d0:	74 0f                	je     f01013e1 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01013d2:	83 c0 01             	add    $0x1,%eax
f01013d5:	0f b6 10             	movzbl (%eax),%edx
f01013d8:	84 d2                	test   %dl,%dl
f01013da:	75 f2                	jne    f01013ce <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01013dc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01013e1:	5d                   	pop    %ebp
f01013e2:	c3                   	ret    

f01013e3 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01013e3:	55                   	push   %ebp
f01013e4:	89 e5                	mov    %esp,%ebp
f01013e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013ed:	eb 03                	jmp    f01013f2 <strfind+0xf>
f01013ef:	83 c0 01             	add    $0x1,%eax
f01013f2:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01013f5:	38 ca                	cmp    %cl,%dl
f01013f7:	74 04                	je     f01013fd <strfind+0x1a>
f01013f9:	84 d2                	test   %dl,%dl
f01013fb:	75 f2                	jne    f01013ef <strfind+0xc>
			break;
	return (char *) s;
}
f01013fd:	5d                   	pop    %ebp
f01013fe:	c3                   	ret    

f01013ff <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01013ff:	55                   	push   %ebp
f0101400:	89 e5                	mov    %esp,%ebp
f0101402:	57                   	push   %edi
f0101403:	56                   	push   %esi
f0101404:	53                   	push   %ebx
f0101405:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101408:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010140b:	85 c9                	test   %ecx,%ecx
f010140d:	74 36                	je     f0101445 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010140f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101415:	75 28                	jne    f010143f <memset+0x40>
f0101417:	f6 c1 03             	test   $0x3,%cl
f010141a:	75 23                	jne    f010143f <memset+0x40>
		c &= 0xFF;
f010141c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101420:	89 d3                	mov    %edx,%ebx
f0101422:	c1 e3 08             	shl    $0x8,%ebx
f0101425:	89 d6                	mov    %edx,%esi
f0101427:	c1 e6 18             	shl    $0x18,%esi
f010142a:	89 d0                	mov    %edx,%eax
f010142c:	c1 e0 10             	shl    $0x10,%eax
f010142f:	09 f0                	or     %esi,%eax
f0101431:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101433:	89 d8                	mov    %ebx,%eax
f0101435:	09 d0                	or     %edx,%eax
f0101437:	c1 e9 02             	shr    $0x2,%ecx
f010143a:	fc                   	cld    
f010143b:	f3 ab                	rep stos %eax,%es:(%edi)
f010143d:	eb 06                	jmp    f0101445 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010143f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101442:	fc                   	cld    
f0101443:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101445:	89 f8                	mov    %edi,%eax
f0101447:	5b                   	pop    %ebx
f0101448:	5e                   	pop    %esi
f0101449:	5f                   	pop    %edi
f010144a:	5d                   	pop    %ebp
f010144b:	c3                   	ret    

f010144c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010144c:	55                   	push   %ebp
f010144d:	89 e5                	mov    %esp,%ebp
f010144f:	57                   	push   %edi
f0101450:	56                   	push   %esi
f0101451:	8b 45 08             	mov    0x8(%ebp),%eax
f0101454:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101457:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010145a:	39 c6                	cmp    %eax,%esi
f010145c:	73 35                	jae    f0101493 <memmove+0x47>
f010145e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101461:	39 d0                	cmp    %edx,%eax
f0101463:	73 2e                	jae    f0101493 <memmove+0x47>
		s += n;
		d += n;
f0101465:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101468:	89 d6                	mov    %edx,%esi
f010146a:	09 fe                	or     %edi,%esi
f010146c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101472:	75 13                	jne    f0101487 <memmove+0x3b>
f0101474:	f6 c1 03             	test   $0x3,%cl
f0101477:	75 0e                	jne    f0101487 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101479:	83 ef 04             	sub    $0x4,%edi
f010147c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010147f:	c1 e9 02             	shr    $0x2,%ecx
f0101482:	fd                   	std    
f0101483:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101485:	eb 09                	jmp    f0101490 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101487:	83 ef 01             	sub    $0x1,%edi
f010148a:	8d 72 ff             	lea    -0x1(%edx),%esi
f010148d:	fd                   	std    
f010148e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101490:	fc                   	cld    
f0101491:	eb 1d                	jmp    f01014b0 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101493:	89 f2                	mov    %esi,%edx
f0101495:	09 c2                	or     %eax,%edx
f0101497:	f6 c2 03             	test   $0x3,%dl
f010149a:	75 0f                	jne    f01014ab <memmove+0x5f>
f010149c:	f6 c1 03             	test   $0x3,%cl
f010149f:	75 0a                	jne    f01014ab <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01014a1:	c1 e9 02             	shr    $0x2,%ecx
f01014a4:	89 c7                	mov    %eax,%edi
f01014a6:	fc                   	cld    
f01014a7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014a9:	eb 05                	jmp    f01014b0 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01014ab:	89 c7                	mov    %eax,%edi
f01014ad:	fc                   	cld    
f01014ae:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01014b0:	5e                   	pop    %esi
f01014b1:	5f                   	pop    %edi
f01014b2:	5d                   	pop    %ebp
f01014b3:	c3                   	ret    

f01014b4 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01014b4:	55                   	push   %ebp
f01014b5:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01014b7:	ff 75 10             	pushl  0x10(%ebp)
f01014ba:	ff 75 0c             	pushl  0xc(%ebp)
f01014bd:	ff 75 08             	pushl  0x8(%ebp)
f01014c0:	e8 87 ff ff ff       	call   f010144c <memmove>
}
f01014c5:	c9                   	leave  
f01014c6:	c3                   	ret    

f01014c7 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01014c7:	55                   	push   %ebp
f01014c8:	89 e5                	mov    %esp,%ebp
f01014ca:	56                   	push   %esi
f01014cb:	53                   	push   %ebx
f01014cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01014cf:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014d2:	89 c6                	mov    %eax,%esi
f01014d4:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014d7:	eb 1a                	jmp    f01014f3 <memcmp+0x2c>
		if (*s1 != *s2)
f01014d9:	0f b6 08             	movzbl (%eax),%ecx
f01014dc:	0f b6 1a             	movzbl (%edx),%ebx
f01014df:	38 d9                	cmp    %bl,%cl
f01014e1:	74 0a                	je     f01014ed <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01014e3:	0f b6 c1             	movzbl %cl,%eax
f01014e6:	0f b6 db             	movzbl %bl,%ebx
f01014e9:	29 d8                	sub    %ebx,%eax
f01014eb:	eb 0f                	jmp    f01014fc <memcmp+0x35>
		s1++, s2++;
f01014ed:	83 c0 01             	add    $0x1,%eax
f01014f0:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014f3:	39 f0                	cmp    %esi,%eax
f01014f5:	75 e2                	jne    f01014d9 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01014f7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014fc:	5b                   	pop    %ebx
f01014fd:	5e                   	pop    %esi
f01014fe:	5d                   	pop    %ebp
f01014ff:	c3                   	ret    

f0101500 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101500:	55                   	push   %ebp
f0101501:	89 e5                	mov    %esp,%ebp
f0101503:	53                   	push   %ebx
f0101504:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101507:	89 c1                	mov    %eax,%ecx
f0101509:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010150c:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101510:	eb 0a                	jmp    f010151c <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101512:	0f b6 10             	movzbl (%eax),%edx
f0101515:	39 da                	cmp    %ebx,%edx
f0101517:	74 07                	je     f0101520 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101519:	83 c0 01             	add    $0x1,%eax
f010151c:	39 c8                	cmp    %ecx,%eax
f010151e:	72 f2                	jb     f0101512 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101520:	5b                   	pop    %ebx
f0101521:	5d                   	pop    %ebp
f0101522:	c3                   	ret    

f0101523 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101523:	55                   	push   %ebp
f0101524:	89 e5                	mov    %esp,%ebp
f0101526:	57                   	push   %edi
f0101527:	56                   	push   %esi
f0101528:	53                   	push   %ebx
f0101529:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010152c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010152f:	eb 03                	jmp    f0101534 <strtol+0x11>
		s++;
f0101531:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101534:	0f b6 01             	movzbl (%ecx),%eax
f0101537:	3c 20                	cmp    $0x20,%al
f0101539:	74 f6                	je     f0101531 <strtol+0xe>
f010153b:	3c 09                	cmp    $0x9,%al
f010153d:	74 f2                	je     f0101531 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010153f:	3c 2b                	cmp    $0x2b,%al
f0101541:	75 0a                	jne    f010154d <strtol+0x2a>
		s++;
f0101543:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101546:	bf 00 00 00 00       	mov    $0x0,%edi
f010154b:	eb 11                	jmp    f010155e <strtol+0x3b>
f010154d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101552:	3c 2d                	cmp    $0x2d,%al
f0101554:	75 08                	jne    f010155e <strtol+0x3b>
		s++, neg = 1;
f0101556:	83 c1 01             	add    $0x1,%ecx
f0101559:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010155e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101564:	75 15                	jne    f010157b <strtol+0x58>
f0101566:	80 39 30             	cmpb   $0x30,(%ecx)
f0101569:	75 10                	jne    f010157b <strtol+0x58>
f010156b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010156f:	75 7c                	jne    f01015ed <strtol+0xca>
		s += 2, base = 16;
f0101571:	83 c1 02             	add    $0x2,%ecx
f0101574:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101579:	eb 16                	jmp    f0101591 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010157b:	85 db                	test   %ebx,%ebx
f010157d:	75 12                	jne    f0101591 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010157f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101584:	80 39 30             	cmpb   $0x30,(%ecx)
f0101587:	75 08                	jne    f0101591 <strtol+0x6e>
		s++, base = 8;
f0101589:	83 c1 01             	add    $0x1,%ecx
f010158c:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0101591:	b8 00 00 00 00       	mov    $0x0,%eax
f0101596:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101599:	0f b6 11             	movzbl (%ecx),%edx
f010159c:	8d 72 d0             	lea    -0x30(%edx),%esi
f010159f:	89 f3                	mov    %esi,%ebx
f01015a1:	80 fb 09             	cmp    $0x9,%bl
f01015a4:	77 08                	ja     f01015ae <strtol+0x8b>
			dig = *s - '0';
f01015a6:	0f be d2             	movsbl %dl,%edx
f01015a9:	83 ea 30             	sub    $0x30,%edx
f01015ac:	eb 22                	jmp    f01015d0 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01015ae:	8d 72 9f             	lea    -0x61(%edx),%esi
f01015b1:	89 f3                	mov    %esi,%ebx
f01015b3:	80 fb 19             	cmp    $0x19,%bl
f01015b6:	77 08                	ja     f01015c0 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01015b8:	0f be d2             	movsbl %dl,%edx
f01015bb:	83 ea 57             	sub    $0x57,%edx
f01015be:	eb 10                	jmp    f01015d0 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01015c0:	8d 72 bf             	lea    -0x41(%edx),%esi
f01015c3:	89 f3                	mov    %esi,%ebx
f01015c5:	80 fb 19             	cmp    $0x19,%bl
f01015c8:	77 16                	ja     f01015e0 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01015ca:	0f be d2             	movsbl %dl,%edx
f01015cd:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01015d0:	3b 55 10             	cmp    0x10(%ebp),%edx
f01015d3:	7d 0b                	jge    f01015e0 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01015d5:	83 c1 01             	add    $0x1,%ecx
f01015d8:	0f af 45 10          	imul   0x10(%ebp),%eax
f01015dc:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01015de:	eb b9                	jmp    f0101599 <strtol+0x76>

	if (endptr)
f01015e0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01015e4:	74 0d                	je     f01015f3 <strtol+0xd0>
		*endptr = (char *) s;
f01015e6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015e9:	89 0e                	mov    %ecx,(%esi)
f01015eb:	eb 06                	jmp    f01015f3 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015ed:	85 db                	test   %ebx,%ebx
f01015ef:	74 98                	je     f0101589 <strtol+0x66>
f01015f1:	eb 9e                	jmp    f0101591 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01015f3:	89 c2                	mov    %eax,%edx
f01015f5:	f7 da                	neg    %edx
f01015f7:	85 ff                	test   %edi,%edi
f01015f9:	0f 45 c2             	cmovne %edx,%eax
}
f01015fc:	5b                   	pop    %ebx
f01015fd:	5e                   	pop    %esi
f01015fe:	5f                   	pop    %edi
f01015ff:	5d                   	pop    %ebp
f0101600:	c3                   	ret    
f0101601:	66 90                	xchg   %ax,%ax
f0101603:	66 90                	xchg   %ax,%ax
f0101605:	66 90                	xchg   %ax,%ax
f0101607:	66 90                	xchg   %ax,%ax
f0101609:	66 90                	xchg   %ax,%ax
f010160b:	66 90                	xchg   %ax,%ax
f010160d:	66 90                	xchg   %ax,%ax
f010160f:	90                   	nop

f0101610 <__udivdi3>:
f0101610:	55                   	push   %ebp
f0101611:	57                   	push   %edi
f0101612:	56                   	push   %esi
f0101613:	53                   	push   %ebx
f0101614:	83 ec 1c             	sub    $0x1c,%esp
f0101617:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010161b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010161f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101623:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101627:	85 f6                	test   %esi,%esi
f0101629:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010162d:	89 ca                	mov    %ecx,%edx
f010162f:	89 f8                	mov    %edi,%eax
f0101631:	75 3d                	jne    f0101670 <__udivdi3+0x60>
f0101633:	39 cf                	cmp    %ecx,%edi
f0101635:	0f 87 c5 00 00 00    	ja     f0101700 <__udivdi3+0xf0>
f010163b:	85 ff                	test   %edi,%edi
f010163d:	89 fd                	mov    %edi,%ebp
f010163f:	75 0b                	jne    f010164c <__udivdi3+0x3c>
f0101641:	b8 01 00 00 00       	mov    $0x1,%eax
f0101646:	31 d2                	xor    %edx,%edx
f0101648:	f7 f7                	div    %edi
f010164a:	89 c5                	mov    %eax,%ebp
f010164c:	89 c8                	mov    %ecx,%eax
f010164e:	31 d2                	xor    %edx,%edx
f0101650:	f7 f5                	div    %ebp
f0101652:	89 c1                	mov    %eax,%ecx
f0101654:	89 d8                	mov    %ebx,%eax
f0101656:	89 cf                	mov    %ecx,%edi
f0101658:	f7 f5                	div    %ebp
f010165a:	89 c3                	mov    %eax,%ebx
f010165c:	89 d8                	mov    %ebx,%eax
f010165e:	89 fa                	mov    %edi,%edx
f0101660:	83 c4 1c             	add    $0x1c,%esp
f0101663:	5b                   	pop    %ebx
f0101664:	5e                   	pop    %esi
f0101665:	5f                   	pop    %edi
f0101666:	5d                   	pop    %ebp
f0101667:	c3                   	ret    
f0101668:	90                   	nop
f0101669:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101670:	39 ce                	cmp    %ecx,%esi
f0101672:	77 74                	ja     f01016e8 <__udivdi3+0xd8>
f0101674:	0f bd fe             	bsr    %esi,%edi
f0101677:	83 f7 1f             	xor    $0x1f,%edi
f010167a:	0f 84 98 00 00 00    	je     f0101718 <__udivdi3+0x108>
f0101680:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101685:	89 f9                	mov    %edi,%ecx
f0101687:	89 c5                	mov    %eax,%ebp
f0101689:	29 fb                	sub    %edi,%ebx
f010168b:	d3 e6                	shl    %cl,%esi
f010168d:	89 d9                	mov    %ebx,%ecx
f010168f:	d3 ed                	shr    %cl,%ebp
f0101691:	89 f9                	mov    %edi,%ecx
f0101693:	d3 e0                	shl    %cl,%eax
f0101695:	09 ee                	or     %ebp,%esi
f0101697:	89 d9                	mov    %ebx,%ecx
f0101699:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010169d:	89 d5                	mov    %edx,%ebp
f010169f:	8b 44 24 08          	mov    0x8(%esp),%eax
f01016a3:	d3 ed                	shr    %cl,%ebp
f01016a5:	89 f9                	mov    %edi,%ecx
f01016a7:	d3 e2                	shl    %cl,%edx
f01016a9:	89 d9                	mov    %ebx,%ecx
f01016ab:	d3 e8                	shr    %cl,%eax
f01016ad:	09 c2                	or     %eax,%edx
f01016af:	89 d0                	mov    %edx,%eax
f01016b1:	89 ea                	mov    %ebp,%edx
f01016b3:	f7 f6                	div    %esi
f01016b5:	89 d5                	mov    %edx,%ebp
f01016b7:	89 c3                	mov    %eax,%ebx
f01016b9:	f7 64 24 0c          	mull   0xc(%esp)
f01016bd:	39 d5                	cmp    %edx,%ebp
f01016bf:	72 10                	jb     f01016d1 <__udivdi3+0xc1>
f01016c1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01016c5:	89 f9                	mov    %edi,%ecx
f01016c7:	d3 e6                	shl    %cl,%esi
f01016c9:	39 c6                	cmp    %eax,%esi
f01016cb:	73 07                	jae    f01016d4 <__udivdi3+0xc4>
f01016cd:	39 d5                	cmp    %edx,%ebp
f01016cf:	75 03                	jne    f01016d4 <__udivdi3+0xc4>
f01016d1:	83 eb 01             	sub    $0x1,%ebx
f01016d4:	31 ff                	xor    %edi,%edi
f01016d6:	89 d8                	mov    %ebx,%eax
f01016d8:	89 fa                	mov    %edi,%edx
f01016da:	83 c4 1c             	add    $0x1c,%esp
f01016dd:	5b                   	pop    %ebx
f01016de:	5e                   	pop    %esi
f01016df:	5f                   	pop    %edi
f01016e0:	5d                   	pop    %ebp
f01016e1:	c3                   	ret    
f01016e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01016e8:	31 ff                	xor    %edi,%edi
f01016ea:	31 db                	xor    %ebx,%ebx
f01016ec:	89 d8                	mov    %ebx,%eax
f01016ee:	89 fa                	mov    %edi,%edx
f01016f0:	83 c4 1c             	add    $0x1c,%esp
f01016f3:	5b                   	pop    %ebx
f01016f4:	5e                   	pop    %esi
f01016f5:	5f                   	pop    %edi
f01016f6:	5d                   	pop    %ebp
f01016f7:	c3                   	ret    
f01016f8:	90                   	nop
f01016f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101700:	89 d8                	mov    %ebx,%eax
f0101702:	f7 f7                	div    %edi
f0101704:	31 ff                	xor    %edi,%edi
f0101706:	89 c3                	mov    %eax,%ebx
f0101708:	89 d8                	mov    %ebx,%eax
f010170a:	89 fa                	mov    %edi,%edx
f010170c:	83 c4 1c             	add    $0x1c,%esp
f010170f:	5b                   	pop    %ebx
f0101710:	5e                   	pop    %esi
f0101711:	5f                   	pop    %edi
f0101712:	5d                   	pop    %ebp
f0101713:	c3                   	ret    
f0101714:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101718:	39 ce                	cmp    %ecx,%esi
f010171a:	72 0c                	jb     f0101728 <__udivdi3+0x118>
f010171c:	31 db                	xor    %ebx,%ebx
f010171e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101722:	0f 87 34 ff ff ff    	ja     f010165c <__udivdi3+0x4c>
f0101728:	bb 01 00 00 00       	mov    $0x1,%ebx
f010172d:	e9 2a ff ff ff       	jmp    f010165c <__udivdi3+0x4c>
f0101732:	66 90                	xchg   %ax,%ax
f0101734:	66 90                	xchg   %ax,%ax
f0101736:	66 90                	xchg   %ax,%ax
f0101738:	66 90                	xchg   %ax,%ax
f010173a:	66 90                	xchg   %ax,%ax
f010173c:	66 90                	xchg   %ax,%ax
f010173e:	66 90                	xchg   %ax,%ax

f0101740 <__umoddi3>:
f0101740:	55                   	push   %ebp
f0101741:	57                   	push   %edi
f0101742:	56                   	push   %esi
f0101743:	53                   	push   %ebx
f0101744:	83 ec 1c             	sub    $0x1c,%esp
f0101747:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010174b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010174f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101753:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101757:	85 d2                	test   %edx,%edx
f0101759:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010175d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101761:	89 f3                	mov    %esi,%ebx
f0101763:	89 3c 24             	mov    %edi,(%esp)
f0101766:	89 74 24 04          	mov    %esi,0x4(%esp)
f010176a:	75 1c                	jne    f0101788 <__umoddi3+0x48>
f010176c:	39 f7                	cmp    %esi,%edi
f010176e:	76 50                	jbe    f01017c0 <__umoddi3+0x80>
f0101770:	89 c8                	mov    %ecx,%eax
f0101772:	89 f2                	mov    %esi,%edx
f0101774:	f7 f7                	div    %edi
f0101776:	89 d0                	mov    %edx,%eax
f0101778:	31 d2                	xor    %edx,%edx
f010177a:	83 c4 1c             	add    $0x1c,%esp
f010177d:	5b                   	pop    %ebx
f010177e:	5e                   	pop    %esi
f010177f:	5f                   	pop    %edi
f0101780:	5d                   	pop    %ebp
f0101781:	c3                   	ret    
f0101782:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101788:	39 f2                	cmp    %esi,%edx
f010178a:	89 d0                	mov    %edx,%eax
f010178c:	77 52                	ja     f01017e0 <__umoddi3+0xa0>
f010178e:	0f bd ea             	bsr    %edx,%ebp
f0101791:	83 f5 1f             	xor    $0x1f,%ebp
f0101794:	75 5a                	jne    f01017f0 <__umoddi3+0xb0>
f0101796:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010179a:	0f 82 e0 00 00 00    	jb     f0101880 <__umoddi3+0x140>
f01017a0:	39 0c 24             	cmp    %ecx,(%esp)
f01017a3:	0f 86 d7 00 00 00    	jbe    f0101880 <__umoddi3+0x140>
f01017a9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017ad:	8b 54 24 04          	mov    0x4(%esp),%edx
f01017b1:	83 c4 1c             	add    $0x1c,%esp
f01017b4:	5b                   	pop    %ebx
f01017b5:	5e                   	pop    %esi
f01017b6:	5f                   	pop    %edi
f01017b7:	5d                   	pop    %ebp
f01017b8:	c3                   	ret    
f01017b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017c0:	85 ff                	test   %edi,%edi
f01017c2:	89 fd                	mov    %edi,%ebp
f01017c4:	75 0b                	jne    f01017d1 <__umoddi3+0x91>
f01017c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01017cb:	31 d2                	xor    %edx,%edx
f01017cd:	f7 f7                	div    %edi
f01017cf:	89 c5                	mov    %eax,%ebp
f01017d1:	89 f0                	mov    %esi,%eax
f01017d3:	31 d2                	xor    %edx,%edx
f01017d5:	f7 f5                	div    %ebp
f01017d7:	89 c8                	mov    %ecx,%eax
f01017d9:	f7 f5                	div    %ebp
f01017db:	89 d0                	mov    %edx,%eax
f01017dd:	eb 99                	jmp    f0101778 <__umoddi3+0x38>
f01017df:	90                   	nop
f01017e0:	89 c8                	mov    %ecx,%eax
f01017e2:	89 f2                	mov    %esi,%edx
f01017e4:	83 c4 1c             	add    $0x1c,%esp
f01017e7:	5b                   	pop    %ebx
f01017e8:	5e                   	pop    %esi
f01017e9:	5f                   	pop    %edi
f01017ea:	5d                   	pop    %ebp
f01017eb:	c3                   	ret    
f01017ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017f0:	8b 34 24             	mov    (%esp),%esi
f01017f3:	bf 20 00 00 00       	mov    $0x20,%edi
f01017f8:	89 e9                	mov    %ebp,%ecx
f01017fa:	29 ef                	sub    %ebp,%edi
f01017fc:	d3 e0                	shl    %cl,%eax
f01017fe:	89 f9                	mov    %edi,%ecx
f0101800:	89 f2                	mov    %esi,%edx
f0101802:	d3 ea                	shr    %cl,%edx
f0101804:	89 e9                	mov    %ebp,%ecx
f0101806:	09 c2                	or     %eax,%edx
f0101808:	89 d8                	mov    %ebx,%eax
f010180a:	89 14 24             	mov    %edx,(%esp)
f010180d:	89 f2                	mov    %esi,%edx
f010180f:	d3 e2                	shl    %cl,%edx
f0101811:	89 f9                	mov    %edi,%ecx
f0101813:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101817:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010181b:	d3 e8                	shr    %cl,%eax
f010181d:	89 e9                	mov    %ebp,%ecx
f010181f:	89 c6                	mov    %eax,%esi
f0101821:	d3 e3                	shl    %cl,%ebx
f0101823:	89 f9                	mov    %edi,%ecx
f0101825:	89 d0                	mov    %edx,%eax
f0101827:	d3 e8                	shr    %cl,%eax
f0101829:	89 e9                	mov    %ebp,%ecx
f010182b:	09 d8                	or     %ebx,%eax
f010182d:	89 d3                	mov    %edx,%ebx
f010182f:	89 f2                	mov    %esi,%edx
f0101831:	f7 34 24             	divl   (%esp)
f0101834:	89 d6                	mov    %edx,%esi
f0101836:	d3 e3                	shl    %cl,%ebx
f0101838:	f7 64 24 04          	mull   0x4(%esp)
f010183c:	39 d6                	cmp    %edx,%esi
f010183e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101842:	89 d1                	mov    %edx,%ecx
f0101844:	89 c3                	mov    %eax,%ebx
f0101846:	72 08                	jb     f0101850 <__umoddi3+0x110>
f0101848:	75 11                	jne    f010185b <__umoddi3+0x11b>
f010184a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010184e:	73 0b                	jae    f010185b <__umoddi3+0x11b>
f0101850:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101854:	1b 14 24             	sbb    (%esp),%edx
f0101857:	89 d1                	mov    %edx,%ecx
f0101859:	89 c3                	mov    %eax,%ebx
f010185b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010185f:	29 da                	sub    %ebx,%edx
f0101861:	19 ce                	sbb    %ecx,%esi
f0101863:	89 f9                	mov    %edi,%ecx
f0101865:	89 f0                	mov    %esi,%eax
f0101867:	d3 e0                	shl    %cl,%eax
f0101869:	89 e9                	mov    %ebp,%ecx
f010186b:	d3 ea                	shr    %cl,%edx
f010186d:	89 e9                	mov    %ebp,%ecx
f010186f:	d3 ee                	shr    %cl,%esi
f0101871:	09 d0                	or     %edx,%eax
f0101873:	89 f2                	mov    %esi,%edx
f0101875:	83 c4 1c             	add    $0x1c,%esp
f0101878:	5b                   	pop    %ebx
f0101879:	5e                   	pop    %esi
f010187a:	5f                   	pop    %edi
f010187b:	5d                   	pop    %ebp
f010187c:	c3                   	ret    
f010187d:	8d 76 00             	lea    0x0(%esi),%esi
f0101880:	29 f9                	sub    %edi,%ecx
f0101882:	19 d6                	sbb    %edx,%esi
f0101884:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101888:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010188c:	e9 18 ff ff ff       	jmp    f01017a9 <__umoddi3+0x69>
