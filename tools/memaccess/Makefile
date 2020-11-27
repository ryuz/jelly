
TARGET = memwrite memread memdump
INSTALL_PATH=~/.local/bin

all: $(TARGET)

memwrite: memwrite.cpp
	g++ -O2 memwrite.cpp -o memwrite

memread: memread.cpp
	g++ -O2 memread.cpp  -o memread

memdump: memdump.cpp
	g++ -O2 memdump.cpp  -o memdump


install: all
	cp $(TARGET) $(INSTALL_PATH)
