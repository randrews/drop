CC = gcc
LUA_DIR = /usr/local/include
FOV_DIR = .

default: kb.so

.c.o:
	${CC} $? -c -o $@ -I${LUA_DIR} -I${FOV_DIR}

kb.so: kb.o
	${CC} *.o -o $@ -shared -undefined dynamic_lookup -lncurses

clean:
	rm -f *~
	rm -f kb.so
	rm -f *.o
