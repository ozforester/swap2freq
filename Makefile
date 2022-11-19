# Copyright (c) 2021 ozforester. All rights reserved.
# Use of this source code is goverened by a MIT license
# that can be found in the LICENSE file.

TARGET	 = swap
SOURCES := $(wildcard *.S)
OBJECTS  = $(SOURCES:.S=.o)
PROC = attiny13
PPROC = t13
CFLAGS = -flto -no-pie -Os -nostartfiles -nodefaultlibs -fno-stack-protector -fno-pic -DF_CPU=4000000 -Wall -mmcu=${PROC}

all:
	avr-gcc ${CFLAGS} -c -Wall ${OPT} -mmcu=${PROC} -o ${TARGET}.o ${TARGET}.S
	avr-gcc ${CFLAGS} -Wall ${OPT} -mmcu=${PROC} -o ${TARGET} ${TARGET}.o
	avr-objcopy -O ihex ${TARGET} ${TARGET}.hex
	avr-size ${TARGET}.o
	avr-size ${TARGET}.hex

flash:
	avrdude -c usbasp -p ${PPROC} -B 10 -U flash:w:${TARGET}.hex

clean:
	rm -f $(OBJECTS) ${TARGET} $(TARGET).o $(TARGET).hex
