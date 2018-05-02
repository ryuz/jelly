.PHONY: all
all: imx219_test



CFLAGS  += -I../../../soft/Utility -I/usr/local/include/opencv2 -I/usr/local/include/opencv
LDFLAGS += -L/usr/local/lib -lopencv_core -lopencv_imgcodecs -lopencv_highgui -lopencv_imgproc


TARGET = imx219_test
OBJS   = main.o

run: all
	sudo ./imx219_test

$(TARGET): $(OBJS)
	g++ $(LDFLAGS) -o $(TARGET) $(OBJS)

main.o: main.cpp I2cAccess.h
	g++ $(CFLAGS) -c main.cpp


.PHONY: clean
clean:
	rm -rf $(TARGET) $(OBJS)

