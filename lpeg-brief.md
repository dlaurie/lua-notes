<style type="text/css">code{white-space: pre;}
body{font-family: Lucida, Times, serif;}
h1,h2,h3,h4{font-family: Lucida, Palatino, serif;
</style>

About beginner's notes in general
---------------------------------

-   Writing a topic up for oneself is one of the best ways of learning it.

-   Once you have learnt it, you can never recapture the difficulty you had in understanding the original.

-   I promise not to re-work these notes to elegance when I know the material well.

-   They are mainly for my own use, especially when I need the information ater not having worked with it for a long time.

-   They are not intended to be comprehensive, only to flatten the learning curve until the reader knows enough not to be daunted by the official documentation.

Brief introduction to LPEG
--------------------------

LPEG is a library for operating on patterns. It is not an alternative to the Lua string library, but it can be used to implement libraries rather like the string library instead of doing it directly in C.

Some words mean very specific things to LPEG.

**string**  
A Lua string, consisting of an arbitrary sequence of bytes. On many systems, one could say "characters" instead.

**pattern**  
A userdata type, containing enough information to characterize a certain property that a string might have. The properties that can be described are rather like the questions solvers of crossword puzzles tend to ask. For example: "seven letters, starts with 'p', has a double letter in it somewere".

**subject**  
A string that is presented for examination to an LPEG function. Its bytes are referred to as "input".

**match**  
Not the same as `string.match`. In fact, it may be a good idea to forget everything you know about the Lua string library while coming to grips with LPEG.

1.  If a string has the property determined by a pattern, the pattern is said to *match* the string. I.e. it is the pattern, not the string, that does the matching.
2.  The name of an LPEG function that applies a pattern to a subject in an attempt to find a matched substring.
3.  The string matched by a pattern, especially when it is only a substring of the subject.

The central function of LPEG.

**success**  
A pattern *succeeds* when it matches a substring of the subject at the point where it is applied.

**failure**  
A pattern *fails* when it does not match any substring at that point.

**capture**  
Not just a portion of a match.

1.  One of the individually accessible Lua values returned by some patterns.
2.  To return such a value.
3.  A capture pattern.

**capture pattern**  
A pattern that returns one or more captures when it succeeds.

**consume**  
A pattern *consumes* its match if that portion of the subject is not available to any follow-up pattern except a backspace pattern.

The most spectacular feature of LPEG is the way complicated patterns are built up from simpler ones: *Patterns can be used instead of numbers as the values that the variables in an arithmetic expression may take*. For example, `x^2+3*x-13` is a perfectly valid LPEG expression when `x` is a pattern.

Roberto Ierusalimschy put a lot of thought into allocating useful meanings to the arithmetic operations and constants of Lua. In particular, the priority of operations is such that one often needs no parentheses. Some words of warning, though:

-   If you use constants like `3` or `true` in a pattern expression, they cannot be combined with each other, only with existing patterns. To make sure, convert them to patterns first by applying `lpeg.P` (the `lpeg.` is used only here, it will be just `P` later).
-   The expressions look familiar but that must not mislead you into thinking that the usual commutative, associative and distributive laws of algebra hold. They don't.

*Nil is not a valid pattern.*  
This goes without saying, but I am nevertheless saying it.

*Booleans denote success or failure.*  
`true` stands for a pattern that always succeeds, `false` for a pattern that always fails.

*Strings correspond to themselves.*  
A string stands for a pattern that matches only that exact string.

*Integers correspond to string length.*  
`0` stands for a pattern that matches the empty string, positive `n` for a pattern that matches exactly `n` bytes, `-n` for the negation of `n` (see next item).

*Negation means reversal of fortune.*  
`-p` succeeds when `p` fails. It consumes no input. `-n` succeeds when there are fewer than `n` bytes of input left. In particular, the idiom `-1` matches only the end of the subject.

*Length means don't consume.*  
`#p` matches what `p` matches, but consumes no input.

*Multiplication corresponds to concatenation.*  
Suppose `p` and `q` respectively match `a` and `b`, then `p*q` matches `a..b`. Note that multiplication is not commutative.

A common idiom: `#p*q` matches what `q` matches, provided that `p` succeeds.

*Addition corresponds to shortcut `or`.*  
`p+q` matches what `p` matches, except when `p` fails; then it matches what `q` matches. Note that `p+q` succeeds if and only if `q+p` succeeds, but if both `p` and `q` would succeed, the match is that of the first pattern. So addition is not quite commutative.

*Subtraction corresponds to reverse shortcut `and not`.*  
`p-q` fails if `q` succeeds, otherwise matches what `p` matches. Note that `0-p` does the same as `-p`, but `p-p` does not do the same as `0`, it does the same as `false`.

*Division means process the captures.*  
`p/s` matches what `p` does, and defines a capture for the whole expression by processing the captures of `p` as specified by `s`. Call the captures `c_1`, `c_2` etc. If `p` defines no capture, the whole substring matched by `p` counts as `c_1`. There are four variations, depending on the type of `s`.

-   number: `p/n` means the capture is `c_n`.
-   table: `p/tbl` means the capture is `tbl[c_1]`.
-   string: `p/str` means the capture is the result of replacing in `str` all instances of `"%1"` by `c_1`, `"%2"` by `c_2`, etc. This feature can only handle nine captures.
-   function: `p/fct` means the capture (or perhaps several captures) is `fct(c_1,c_2,...)`.

This is the easiest way to make a pattern that returns captures. There is much more below under [Captures](#captures).

*Exponentiation corresponds to repetition.*  
Not quite exponentiation in the usual sense: `p*p` means *exactly* two repetitions of `p`, which is not the same as `p^2`.

-   `p^n` matches `n` or more repetitions of `p`.
-   `p^0` matches any number of repetitions of `p`.
-   `p^-n` matches not more than `n` repetitions of `p`.

The pattern `p` must not match the empty string.

For example, suppose `x=P"abc"`. Then `x^2+3*x-13` means "two or more copies of `abc`, or any three bytes followed by `abc`, but not 13 or more bytes long".

Some LPEG functions
-------------------

The introductory `lpeg.` has been omitted here.

### Pattern constructors

**`P`** (**P**attern)  
Apart from nil, boolean, string and number, discussed above, functions and tables can also be converted to patterns, but these are too advanced to discuss here. Existing patterns are unchanged.

**`R`** (**R**ange)  
`R(r)`, where `r` is a two-byte string, matches any byte whose internal numerical code is in the range `r:byte(1,2)`. You could use characters in `r`, e.g. R"az" on most systems matches the range of lowercase letters, but see `locale` for a more portable alternative.

**`S`** (**S**et)  
S(s), where `s` is a string, matches any of the bytes in `s`.

**`locale`**  
`locale()` returns a table of patterns that match character classes. Recommended method is to examine the keys of the returned table, e.g. `locale().lower` matches all lower-case letters.

### Pattern methods

When called with `p` as first argument, these functions will replace `p` by `P(p)` before proceeding. When `p` is already a pattern, they can also be called in an object-oriented way, as occasionally shown below.

**`match(p,subject[,init]), match(p,subject,init, ...)`**  
Tries to match `p` to `subject:sub(init)`. `init` defaults to 1. Returns the captures of the match, or if none specified, the index of the first byte in the subject after the match. As indicated, you may not omit the `init` argument to `match` when there are extra arguments. Those optional arguments can be accessed as described under [Captures](#captures).

**`B(p), p:B()`** (**B**ackspace)  
Matches what `p` does, but matches just before the current position in the subject instead of at it and consumes no input. `p` is restricted to patterns of fixed length that make no captures.

**`C(p), p:C()`** (**C**apture)  
Matches what `p` does, and returns a capture of the match, plus all captures that were made.

Advanced topics
---------------

The official documentation has material on:

-   `P` acting on tables and functions.

-   Grammars.

The LPEG distribution also contains `re.lua`, an application demonstrating the feasibility of writing a regular expression handler using LPEG.

The present author is not yet qualified to write about these. He is probably not qualified to write about the topics below either, but he wants to be.

### Captures

Captures made by a subexpression automatically become captures of the whole expression, and are eventually returned by `match`, unless modified by the division operator and the capture methods.

The patterns made by `P` acting on a non-pattern do not capture anything. They can be made to do so with the four options provided by the division operator. In principle one can do almost anything that way, since one of the options is to process everything by a function of one's own choosing.

In practice some tasks are so common that it is useful to have additional capture functions predefined. We are reaching the limits of this primer here, and there is really no substitute for reading the official LPEG documentation, but at the risk of saying too much but not enough, here are some of them.

The pattern `p1=P'a'/"A"+P'b'/"B"+P'c'/"C"`, which matches lower-case `a`, `b` or `c` and captures the upper-case equivalent, is used in some of the examples.

**`Carg(n)`**  
Captures the `n`-th extra argument to `match`. `(p1*Carg(1)*p1):match("ab",1,2)` returns `'A',2,'B'` (the `1` is the non-optional `init` argument).

**`Cp()`** (**p**osition)  
Captures the position in the subject that has been reached, i.e. `n+1` when the input up to position `n` has been consumed. `(p1*p1*Cp()):match("ab")` returns `'A','B',3`.

**`Cc(...)`** (**c**onstant)  
Captures all its arguments. `(p1+Cc(math.pi)):match"xyz"` returns `3.1415926535898`.

**`Ct(p), p:Ct()`** (**t**able)  
Captures a table containing all the captures of `p`. `Ct(p1*Carg(1)*p1):match("ab",1,2)[3]` is `B`.

**`Cs(p), p:Cs()`** (**s**ubstitute in **s**tring)  
Substitute the matched substring in the full match by its captured value. `Cs(p1*Carg(1)*p1):match("ab",1,2)` returns `A2B`. The captures must be strings. Note that the substitution applies to the match, not to the full subject: `Cs(p1*Carg(1)*p1):match("abc",1,2)` also returns `A2B`.

**`Cf(p,fct), p:Cf(fct)`** (**f**old by **f**unction)  
`fct` must be a function of two variables. Think of it as a left-associative binary operator applied between the captures of `p`. The result is the capture of `Cf(p,fct)`. `(C(1)^3):match"361"` returns `'3','6','1'` but `Cf(C(1)^3,math.max):match"361"` returns `6`.

The remaining capture functions: `Cg`, `Cb` and `Cmt`, are definitely out of scope for this primer.

* * * * *

\<- *About this document:* Dirk Laurie wrote it in order to teach himself LPEG. All errors in it can be blamed on his inexperience. The original is `lpeg-brief.txt`, which is written in Pandoc Markdown. The other versions were made using Pandoc <http://www.johnmacfarlane.com/pandoc>.
