EXAMPLES=\
	example2_1.nim \
	example2_2.nim \
	example2_3.nim \
	example2_4.nim \
	example2_5.nim \
	example3_10.nim \
	example3_11.nim \
	example3_1.nim \
	example3_2.nim \
	example3_3.nim \
	example3_4.nim \
	example3_5.nim \
	example3_6.nim \
	example3_7.nim \
	example3_8.nim \
	example3_9.nim \
	simple_notepad.nim 

TARGETS=$(EXAMPLES:.nim=)

all: $(EXAMPLES:.nim=)

%: %.nim
	nim c --out:../build-nim-iup-examples-nim-Debug/$@ --nimCache:../build-nim-iup-examples-nim-Debug/nimcache $^

clean:
	rm -rf ../build-nim-iup-examples-nim-Debug/
