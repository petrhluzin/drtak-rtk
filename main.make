INCDIR = /usr/local/avr/include
CC = /usr/local/bin/avr-gcc
OBJCOPY = /usr/local/bin/avr-objcopy
#COMMONOPT = -g -DTICK_FREQ=1000 -DISR_FREQ=2000 -DTIMER_ISR=SIG_OUTPUT_COMPARE2 \
#						-DTIMER_APP_CALL=timerAppCall
#COMMONOPT = -g -DTICK_FREQ=1000 -DISR_FREQ=5000 -DTIMER_ISR=SIG_OUTPUT_COMPARE2 \
#						-DTIMER_APP_CALL=timerAppCall # -DTIMER_RTK_PREEMPT=1
#ASFLAGS = $(COMMONOPT) -mmcu=atmega128 -D__ASM__
#CFLAGS = $(COMMONOPT) -O3 -mmcu=atmega128 # don't forget, otherwise defaulted to 8515!
                        # the mmcu option also controls how the linker
												# links (which linker script file to use)
#LDFLAGS = -g -mmcu=atmega128

#C_SRCFILES = shio.c uartIsrC.c timeout.c ab-display.c ui-obj.c schedule.c \
#					   diffSteer.c test38kh.c servo.c
#ASM_SRCFILES = rtk.S uartIsr.S cq.S int-math.S progmem.S timer.S

OBJFILES  := $(C_SRCFILES:.c=.o) $(ASM_SRCFILES:.S=.o)
$(MAIN_SRCFILE:.c=.out):  $(OBJFILES)

include $(C_SRCFILES:.c=.d)
include $(ASM_SRCFILES:.S=.d)
#include $(*:.c=.d)
#include $(*:.S=.d)
#include *.d

%.s:	%.c

#%.o:	%.c %.d
#	$(CC) $(CCOPT) $(COMMONOPT) -c $<
#
#%.o:	%.S %.d
#	$(CC) $(ASMOPT) $(COMMONOPT) -c $<

%.out:	%.o
	$(CC) $(LDFLAGS) $^ -o $@

%.hex:	%.out
	$(OBJCOPY) -O ihex $< $@

%.srec:	%.out
	$(OBJCOPY) -O srec $< $@

%.d:	%.c
	set -e; $(CC) $(CFLAGS) $^ -MM \
	| sed 's/\($*\)\.o[ :]*/\1.o $@ : /g' > $@; \
	[ -s $@ ] || rm -f $@

%.d:	%.S
	set -e; $(CC) $(ASFLAGS) $^ -MM \
	| sed 's/\($*\)\.o[ :]*/\1.o $@ : /g' > $@; \
	[ -s $@ ] || rm -f $@

%.o:	%.d

%.up: %.srec
	./erase
	./upload $<

clean:
	rm -f $(OBJFILES:.o=.d)
	rm -f $(C_SRCFILES:.c=.s)
	rm -f $(OBJFILES)
	rm -f $(MAIN_SRCFILE:.c=.out)
	rm -f $(MAIN_SRCFILE:.c=.srec)
	rm -f $(MAIN_SRCFILE:.c=.hex)

