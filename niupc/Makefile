TARGETS=\
	example2_1 \
	example2_2 \
	example2_3 \
	example2_4 \
	example2_5 \
	example2_5_niupext \
	example3_10 \
	example3_11 \
	example3_1 \
	example3_2 \
	example3_3 \
	example3_4 \
	example3_5 \
	example3_6 \
	example3_7 \
	example3_8 \
	example3_9 \
        simple_notepad \
	simple_notepad_niupext \
        scintilla_notepad \
	example4_1 \
	example4_2 \
	example4_3 \
	example4_4 \
	list1 \
	list2 \
	list3 \
	matrixlist \
	matrix \
	tree \
	flattree \
	webbrowser \
	plot \
	version

OUTDIR=/mnt/ssd/tmp/build-nim-iup-examples-nim-Debug/niupc
NIMCOPT=--gc:orc -d:release --debugInfo --lineDir:on

OBJS:=$(addprefix $(OUTDIR)/,$(TARGETS))

all: $(OBJS)

$(OUTDIR)/%: %.nim
	nim c $(NIMCOPT) --out:$@ $^
	#nim c --cpu:amd64 --os:windows --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc --out:$@.exe $(NIMCOPT) $^
	echo
	
clean:
	rm -rf $(OUTDIR)



