TEX_MAIN = assignment2.tex

all: assignment2

assignment2: $(TEX_MAIN)
	xelatex -pdf $(TEX_MAIN)

clean:
	latexmk -c $(TEX_MAIN)
	rm -f *.bbl 