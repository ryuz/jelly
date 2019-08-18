

CFLAGS  += -I../../../soft/Utility -I/usr/local/include/opencv2 -I/usr/local/include/opencv
LDFLAGS += -L/usr/local/lib -lopencv_core -lopencv_imgcodecs -lopencv_highgui -lopencv_imgproc


TARGET = mnist_demo
OBJS   = main.o oled.o

.PHONY: all
all: $(TARGET)

run: all
	sudo ./$(TARGET) gui

start: all
	sudo ./$(TARGET)

$(TARGET): $(OBJS)
	g++ $(LDFLAGS) -o $(TARGET) $(OBJS)

main.o: main.cpp I2cAccess.h
	g++ $(CFLAGS) -c main.cpp

oled.o: oled.cpp
	g++ $(CFLAGS) -c oled.cpp


.PHONY: clean
clean:
	rm -rf $(TARGET) $(OBJS)

