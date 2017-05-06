all: lpeg-brief.html lpeg-brief.md upvalues.html glossary.html glossary-m.html upvalues.html

clean:
	-rm lpeg-brief.md *.html *~

%.md: %.txt
	pandoc -s $*.txt -t markdown_github -o $*.md

PANDOCFLAGS:=--css=pandoc.css --toc -H header.fragment -A after-body.fragment
EXTRAPANDOC:=

%.html: %.txt
	pandoc $(PANDOCFLAGS) $(EXTRAPANDOC) -s $*.txt -o $*.html
	./munge-body.sh $*.html

*.html: header.fragment after-body.fragment header-glossary.fragment

glossary.html: EXTRAPANDOC := -A header-glossary.fragment

glossary-m.html: glossary.txt
	pandoc $(PANDOCFLAGS) $(EXTRAPANDOC) -s glossary.txt -o glossary-m.html
