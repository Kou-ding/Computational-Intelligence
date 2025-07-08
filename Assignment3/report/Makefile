TEX_MAIN = assignment3.tex

all: assignment3

assignment3: $(TEX_MAIN)
	xelatex -pdf $(TEX_MAIN)

clean:
	latexmk -c $(TEX_MAIN)
	rm -f *.bbl 