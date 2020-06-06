EXAMPLES=\
	example2_1.nim \
	example2_2.nim \
	example2_3.nim \
	example2_4.nim \
	example2_5.nim \
	example2_5_niupext.nim \
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
        simple_notepad.nim \
	simple_notepad_niupext.nim \
        scintilla_notepad.nim \
	example4_1.nim \
	example4_2.nim \
	example4_3.nim \
	example4_4.nim \
	list1.nim \
	list2.nim \
	list3.nim \
	matrixlist.nim \
	matrix.nim \
	tree.nim \
	webbrowser.nim \
	plot \
	version


TARGETS=$(EXAMPLES:.nim=)

all: $(TARGETS)

%: %.nim
	nim c --debugInfo --lineDir:on --out:../build-nim-iup-examples-nim-Debug/$@ --nimCache:../build-nim-iup-examples-nim-Debug/nimcache --gc:arc $^
	nim c --cpu:amd64 --os:windows --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc --out:../build-nim-iup-examples-nim-Debug/$@.exe --nimCache:../build-nim-iup-examples-nim-Debug/nimcache --gc:arc $^

clean:
	rm -rf ../build-nim-iup-examples-nim-Debug/
