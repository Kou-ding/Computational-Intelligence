TEX_MAIN = assignment4.tex

all: assignment4

assignment4: $(TEX_MAIN)
	xelatex -pdf $(TEX_MAIN)

clean:
	latexmk -c $(TEX_MAIN)
	rm -f *.bbl 