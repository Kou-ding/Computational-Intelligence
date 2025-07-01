TEX_MAIN = assignment1.tex

all: assignment1

assignment1: $(TEX_MAIN)
	xelatex -pdf $(TEX_MAIN)

clean:
	latexmk -C $(TEX_MAIN)
	rm -f *.bbl 