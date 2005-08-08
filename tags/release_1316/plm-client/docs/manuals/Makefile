# This file creates the Patch Lifecycle Manager in pdf format
# type 'make' in this directory
#
# Judith Lebzelter   Jan 28, 2004
#
manual.pdf : manual.dvi
	dvipdf manual.dvi
manual.dvi : manual.tex manual.ind
	latex manual.tex
manual.ind : manual.idx
	makeindex manual.idx
manual.idx : manual.tex
	latex manual.tex

clean :
	rm manual.aux  manual.dvi  manual.idx  manual.ilg  manual.ind  manual.log  manual.toc

realclean :
	rm manual.aux  manual.dvi  manual.idx  manual.ilg  manual.ind  manual.log  manual.pdf manual.toc
