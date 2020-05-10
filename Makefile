CC = gcc
ASMBIN = nasm
ifeq ($(OS), Windows_NT)
    FORMAT = win32
    EXTENSION = .exe
    RM = del
    ASMFLAGS = --prefix _
    DEFINES = -D__USE_MINGW_ANSI_STDIO=1
else
    FORMAT = elf
    EXTENSION =
    RM = rm
    ASMFLAGS =
    DEFINES = 
endif

all : asm cc link
asm : 
	$(ASMBIN) -o rgb_triangle.o -f $(FORMAT) $(ASMFLAGS) -g -l rgb_triangle.lst rgb_triangle.asm
cc :
	$(CC) -m32 -c -g -O0 -Wall $(DEFINES) main.c
link :
	$(CC) -m32 -o rgb_triangle$(EXTENSION) rgb_triangle.o main.o
clean :
	$(RM) *.o
	$(RM) rgb_triangle$(EXTENSION)
	$(RM) rgb_triangle.lst
