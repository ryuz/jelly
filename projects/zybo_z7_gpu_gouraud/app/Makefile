.PHONY: all
all: gpu_gouraud

INCLUDE_PATH = ../../../soft/JellyGL

CFLAGS  += -I$(INCLUDE_PATH)
LDFLAGS += 

TARGET = gpu_gouraud
OBJS   = main.o gpu_test.o

run: all
	sudo ./gpu_gouraud

$(TARGET): $(OBJS)
	g++ $(LDFLAGS) -o $(TARGET) $(OBJS)

main.o: main.cpp
	g++ $(CFLAGS) -c main.cpp

gpu_test.o : gpu_test.cpp
	g++ $(CFLAGS) -c gpu_test.cpp


.PHONY: clean
clean:
	rm -rf $(TARGET) $(OBJS)

