NIMCOPT=--gc:orc -d:release --debugInfo --lineDir:on
OUTDIR=/mnt/ssd/tmp/build-nim-iup-examples-nim-Debug/
TARGETS=\
	button \
	text \
	textformat
	#$(OUTDIR)/multiline1 \
	#$(OUTDIR)/multiline2 \


OBJS:=$(addprefix $(OUTDIR)/,$(TARGETS))

all: $(OBJS)

$(OUTDIR)/%: %.nim
	nim c $(NIMCOPT) --out:$@ $^
	#nim c --cpu:amd64 --os:windows --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc --out:$@.exe $(NIMCOPT) $^
	echo

clean:
	rm -rf /mnt/ssd/tmp/build-nim-iup-examples-nim-Debug/
