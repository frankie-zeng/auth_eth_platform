
CC?=gcc



.PHONY:all
all: pps

main.o : main.c 
	$(CC) -c $(INCFLAGS) $(CFLAGS) main.c

pps: main.o
	$(CC) main.o -o pps

clean:
	rm -rf main.o pps


