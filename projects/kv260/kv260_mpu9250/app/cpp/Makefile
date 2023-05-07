
TARGET   = ultra96v2_mpu9250.out

CFLAGS  += -g -O3 -I../../../../include
LDFLAGS += 

OBJS = main.o

.PHONY: all
all: $(TARGET)

.PHONY: clean
clean:
	rm -rf $(TARGET) $(OBJS)

.PHONY: run
run: $(TARGET)
	./$(TARGET)

$(TARGET): $(OBJS)
	g++ $(LDFLAGS) -o $(TARGET) $(OBJS)

%.o : %.cpp
	g++ $(CFLAGS) -c $< -o $@

