TARGET:=lpeg-brief.html lpeg-brief.md upvalues.html glossary.html glossary-m.html upvalues.html

all: $(TARGET)

clean:
	-rm $(TARGET)

%.md: %.txt
	pandoc -s $*.txt -t markdown_github -o $*.md

PANDOCFLAGS:=--css=lua-notes.css --toc
EXTRAPANDOC:=

%.html: %.txt
	pandoc $(PANDOCFLAGS) $(EXTRAPANDOC) -s $*.txt -o $*.html

*.html: lua-notes.css toc-columnize.lua Makefile

glossary-m.html: glossary.txt
	pandoc -s glossary.txt -o glossary-m.html

glossary.html: glossary.txt
	pandoc $(PANDOCFLAGS) $(EXTRAPANDOC) -s glossary.txt -o glossary.html
	lua toc-columnize.lua glossary.html

