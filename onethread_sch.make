MMCU = -mmcu=atmega128
COMMONOPT = -g $(MMCU) \
          -DTICK_FREQ=1000 -DISR_FREQ=5000 -DTIMER_ISR=SIG_OUTPUT_COMPARE2
ASFLAGS = $(COMMONOPT) -D__ASM__
CFLAGS = $(COMMONOPT) -O3 # don't forget, otherwise defaulted to 8515!
                        # the mmcu option also controls how the linker
												# links (which linker script file to use)
LDFLAGS = -g $(MMCU)

MAIN_SRCFILE = onethread_sch.c 
C_SRCFILES = $(MAIN_SRCFILE)
ASM_SRCFILES = rtk.S timer.S

include main.make
