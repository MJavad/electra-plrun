TARGET=plrun
CC=clang
LDID=ldid
CFLAGS= -isysroot /mj/sdks/iPhoneOS11.1.sdk

.PHONY: default all clean
.PRECIOUS: $(TARGET)

default: $(TARGET)
all: default

$(TARGET): $(TARGET).m
	$(CC) $(CFLAGS) $^ -o $@
	$(LDID) -S$(TARGET).ent $(TARGET)

clean:
	rm -f $(TARGET)
