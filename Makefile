all: lpeg-brief.html lpeg-brief.md

%.md: %.txt
	pandoc -s $*.txt -t markdown_github -o $*.md

%.html: %.txt
	pandoc -s $*.txt -o $*.html
