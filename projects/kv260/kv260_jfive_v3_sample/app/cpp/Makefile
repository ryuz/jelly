
TARGET    = kv260_jfive_v3_sample.out


CFLAGS  += -Wall -O2 -I../../../../../include
LDFLAGS += 

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

