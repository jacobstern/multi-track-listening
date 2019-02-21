CFLAGS = -g -Wall -Werror

HEADER_FILES = src

SRC = $(wildcard src/*.c)

OBJ = $(SRC:.c=.o)

LDLIBS ?= -lmpg123 -lmp3lame -lswresample -lavutil -lopenal -lm

PROG ?= priv/c/cruncher

PROG_OUT ?= out.mp3

PROG_ARGS ?= ./example/1.mp3 ./example/2.mp3 -o $(PROG_OUT) -d 60 --start-l 15

NIX_SHELL ?= nix-shell --pure

$(PROG): c_priv $(OBJ)
	$(CC) -I $(HEADER_FILES) -o $@ $(LDFLAGS) $(OBJ) $(LDLIBS)

c_priv:
	mkdir -p priv/c

run: $(PROG)
	time $(PROG) $(PROG_ARGS)

valgrind: $(PROG)
	valgrind --leak-check=yes $(PROG) $(PROG_ARGS)

clean:
	rm -f $(PROG) $(OBJ) $(BEAM_FILES) $(PROG_OUT)
