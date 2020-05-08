CC = gcc
ASMBIN = nasm
ifeq ($(OS), Windows_NT)
    FORMAT = win32
    EXTENSION = .exe
    RM = del
    FLAGS = --prefix _
else
    FORMAT = elf
    EXTENSION =
    RM = rm
    FLAGS =
endif

all : asm cc link
asm : 
	$(ASMBIN) -o rgb_triangle.o -f $(FORMAT) $(FLAGS) -l rgb_triangle.lst rgb_triangle.asm
cc :
	$(CC) -m32 -c -g -O0 -Wall main.c
link :
	$(CC) -m32 -o rgb_triangle$(EXTENSION) rgb_triangle.o main.o
clean :
	$(RM) *.o
	$(RM) rgb_triangle$(EXTENSION)
	$(RM) rgb_triangle.lst
