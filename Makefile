
# Makefile for the ajhresume package. Creates the tgz to upload to CTAN
# Alex Hirzel <alex@hirzel.us>

CLASS=ajhresume
EXAMPLE=example
README=README.md
LICENSE=LICENSE

LATEX=texfot -ignore '^This is \\w*TeX|^Output written on ' -no-stderr latexmk -pdfxe -xelatex -halt-on-error
LATEX_CLEAN=latexmk -c
VALIDATE=./validate_ctan.pl

GENFILES=$(CLASS).cls $(CLASS).pdf $(EXAMPLE).tex $(EXAMPLE).pdf
DISTFILES=$(README) $(LICENSE) $(CLASS).dtx $(CLASS).ins $(GENFILES)
DTX_VERSION=$(shell ltxfileinfo -v $(CLASS).dtx)
GIT_TAG=$(shell git name-rev --tags --name-only $(shell git rev-parse HEAD))
CTANARCHIVE=$(CLASS)-$(DTX_VERSION).tar.gz

DEFAULT: $(GENFILES)

dist: dist/ctan

# get version string from git for a sanity check here
dist/ctan: $(CTANARCHIVE)
	mkdir -p $@
	@echo ""
	@echo Release process for CTAN
	@echo ========================
	@echo Note: target directory on CTAN is macros/latex/contrib/$(CLASS)
	@echo Note: other CTAN information is available in the $(README)
	@echo ""
	$(VALIDATE) $(CTANARCHIVE) "$(DTX_VERSION)"
	@echo performing release sanity checks \(DO NOT RELEASE IF THERE ARE FAILURES\):
ifeq "$(GIT_TAG)" "$(DTX_VERSION)"
	@echo PASS: .dtx version file matches git tag [dtx="$(DTX_VERSION)", git="$(GIT_TAG)"]
else
	@echo FAIL: .dtx version does not match git tag [dtx="$(DTX_VERSION)", git="$(GIT_TAG)"]
endif
ifeq "0" "$(shell grep CheckSum{0} $(CLASS).dtx | wc -l)"
	@echo PASS: file appears to have valid checksum
else
	@echo FAIL: file checksum is zero, update it to a valid value before release
endif
ifeq "0" "$(shell git diff-index HEAD | wc -l)"
	@echo PASS: working directory clean
else
	@echo FAIL: working directory dirty \($(shell git diff-index HEAD | wc -l)\)
endif
	mv $(CTANARCHIVE) $@

	@# copy files into dist folder after archive
	@#$(foreach f,$(DISTFILES),cp $f $@/ctan;)

# Note: CTAN accepts only .zip, .tgz, .tar.gz. The archive file should have a
# Note: CTAN requires a version number which is maintained in the Makefile as v1
# Note: the archive should have a single level of indirection inside (e.g. the
#       README.md file should be ajhresume/README.md within the archive)
$(CTANARCHIVE): $(DISTFILES)
	tar -zcf $@ --show-transformed-names --verbose --xform 's,^,$(CLASS)/,' $^

# unpack the .dtx
$(CLASS).cls $(EXAMPLE).tex: $(CLASS).ins $(CLASS).dtx
	pdflatex $(CLASS).ins

# the class documentation includes a copy of the README converted to LaTeX
$(CLASS).pdf: README.tex
README.tex: $(README)
	pandoc --top-level-division=section -t latex $< | sed '/\\\(section\|hypertarget\){ajhresume}/d' > $@

# the class documentation includes the example's output, so make sure the
# example is compiled first
$(CLASS).pdf: $(EXAMPLE).pdf

# PDFs made from .dtx have a special index
%.pdf: %.dtx
	$(LATEX) $<
	makeindex -s gind.ist $*.idx
	$(LATEX) $<
	$(LATEX_CLEAN) $<
	rm -f $*.xdv $*.glo

# other PDFs from .tex are more normal
%.pdf: %.tex
	$(LATEX) $<
	$(LATEX_CLEAN) $<
	rm -f $*.xdv $*.glo

clean:
	rm -f README.tex
	rm -f $(GENFILES)

distclean: clean
	rm -rf dist

print-version:
	@echo $(DTX_VERSION)

.PHONY: clean print-version DEFAULT

