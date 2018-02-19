
# Makefile for the ajhresume package. Creates the tgz to upload to CTAN
# Alex Hirzel <alex@hirzel.us>

NAME=ajhresume
EXAMPLE=example
README=README.md
LICENSE=LICENSE

LATEX=texfot -ignore '^This is \\w*TeX|^Output written on ' -no-stderr latexmk -pdfxe -xelatex -halt-on-error
LATEX_CLEAN=latexmk -c
VALIDATE=./validate_ctan.pl

GENFILES=$(NAME).cls $(NAME).pdf $(EXAMPLE).tex $(EXAMPLE).pdf
DISTFILES=$(README) $(LICENSE) $(NAME).dtx $(NAME).ins $(GENFILES)
DTX_VERSION=$(shell ltxfileinfo -v $(NAME).dtx)
GIT_TAG=$(shell git name-rev --tags --name-only $(shell git rev-parse HEAD))
CTANARCHIVE=$(NAME)-$(DTX_VERSION).tar.gz

dist: dist/ctan

# get version string from git for a sanity check here
dist/ctan: $(CTANARCHIVE)
	mkdir -p $@
	@echo ""
	@echo Release process for CTAN
	@echo ========================
	@echo Note: target directory on CTAN is macros/latex/contrib/$(NAME)
	@echo Note: other CTAN information is available in the $(README)
	@echo ""
	@echo performing release sanity checks \(DO NOT RELEASE IF THERE ARE FAILURES\):
	$(VALIDATE) $(CTANARCHIVE) "$(DTX_VERSION)"
ifeq "$(GIT_TAG)" "$(DTX_VERSION)"
	@echo PASS: .dtx version file matches git tag [dtx="$(DTX_VERSION)", git="$(GIT_TAG)"]
else
	@echo FAIL: .dtx version does not match git tag [dtx="$(DTX_VERSION)", git="$(GIT_TAG)"]
endif
ifeq "$(shell grep CheckSum{0} $(NAME).dtx | wc -l)" "0"
	@echo PASS: file appears to have valid checksum
else
	@echo FAIL: file checksum is zero, update it to a valid value before release
endif
	mv $(CTANARCHIVE) $@

	@# copy files into dist folder after archive
	@#$(foreach f,$(DISTFILES),cp $f $@/ctan;)

# Note: CTAN accepts only .zip, .tgz, .tar.gz. The archive file should have a
# Note: CTAN requires a version number which is maintained in the Makefile as v1
# Note: the archive should have a single level of indirection inside (e.g. the
#       README.md file should be ajhresume/README.md within the archive)
$(CTANARCHIVE): $(DISTFILES)
	tar -zcf $@ --show-transformed-names --verbose --xform 's,^,$(NAME)/,' $^

# unpack the .dtx
$(NAME).cls $(EXAMPLE).tex: $(NAME).ins $(NAME).dtx
	pdflatex $(NAME).ins

# the class documentation includes a copy of the README converted to LaTeX
$(NAME).pdf: README.tex
README.tex: $(README)
	pandoc --top-level-division=section -t latex $< | sed '/\\\(section\|hypertarget\){ajhresume}/d' > $@

# the class documentation includes the example's output, so make sure the
# example is compiled first
$(NAME).pdf: $(EXAMPLE).pdf

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

.PHONY: clean print-version

