all: lpeg-brief.html lpeg-brief.md upvalues.html glossary.html

%.md: %.txt
	pandoc -s $*.txt -t markdown_github -o $*.md

%.html: %.txt
	pandoc --css=pandoc.css --toc -s $*.txt -o $*.html
