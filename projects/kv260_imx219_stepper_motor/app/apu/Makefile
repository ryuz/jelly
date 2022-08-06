
TARGET    = kv260_imx219_stepper_motor.out
DT_NAME   = kv260_imx219_stepper_motor
BIT_NAME  = kv260_imx219_stepper_motor

CFLAGS  += -Wall -g -O0 -I../../../../include `pkg-config --cflags opencv`
LDFLAGS += -g  `pkg-config --libs opencv`

RUN_OPT ?=

OBJS = main.o

.PHONY: all
all: $(TARGET)

.PHONY: clean
clean:
	rm -rf $(TARGET) $(OBJS)

.PHONY: run
run: $(TARGET)
	./$(TARGET) $(RUN_OPT)

$(TARGET): $(OBJS)
	g++ -o $(TARGET) $(OBJS) $(LDFLAGS)

%.o : %.cpp
	g++ $(CFLAGS) -c $< -o $@

