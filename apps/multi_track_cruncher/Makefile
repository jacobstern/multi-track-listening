CFLAGS = -g -Wall

HEADER_FILES = src

SRC = $(wildcard src/*.c)

OBJ = $(SRC:.c=.o)

LDLIBS ?= -lmpg123 -lmp3lame

PROG ?= priv/c/cruncher

$(PROG): c_priv $(OBJ)
	$(CC) -I $(HEADER_FILES) -o $@ $(LDFLAGS) $(OBJ) $(LDLIBS)

c_priv:
	mkdir -p priv/c

run: $(PROG)
	$(PROG) $(PROG_ARGS)

clean:
	rm -f $(PROG) $(OBJ) $(BEAM_FILES)
