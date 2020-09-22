# list-table

This [Pandoc][] [filter][] allows to convert lists of lists (bullet lists and/or ordered lists) into tables. This makes it easier to type long tables and tables with "complicated" content because you don't need to draw any ASCII art.

The filter can also convert tables to lists of lists, allowing full roundtripping.

[Pandoc]: https://pandoc.org
[filter]: https://pandoc.org/MANUAL.html#option--lua-filter

## Warning

Currently this filter only works with pandoc versions lower than 2.10. If and when I get my head around the pandoc 2.10 table model I will update it so that it also works with pandoc >= 2.10 if it isn't too complicated. If someone already has a good grasp on the pandoc 2.10 table model pull requests are most welcome!

## Contributing/hacking

The filter is written in [MoonScript][] which must be compiled to Lua with the `moonc` program to be used with Pandoc. If you want to do a pull request, or just hack on the filter, you should edit the [pandoc-list-table.moon](pandoc-list-table.moon) file, install MoonScript, then compile the filter code to Lua with `moonc pandoc-list-table.moon`, then check that your modifications work by running pandoc on suitable input with `pandoc-list-table.lua` specified as a Lua filter. **Don't modify `pandoc-list-table.lua` directly!**

[MoonScript]: htrps://moonscript.org

## Usage

Obviously it would be dysfunctional if all lists of lists were converted to tables.  Hence you must tell the filter that you want to convert a given list of list to a table by wrapping the list in a div with the class `lol2table` (short for "list-of-lists-to-table":

````pandoc
:::lol2table
*   -   foo
    -   bar
    -   baz
*   -   +   tic
        +   pic
    -   +   tac
        +   pac
:::
````

When running this through pandoc with the filter enabled and with markdown as output format it is replaced with this:

````pandoc
+---------+---------+-----+
| foo     | bar     | baz |
+=========+=========+=====+
| -   tic | -   tac |     |
| -   pic | -   pac |     |
+---------+---------+-----+
````

Note how each item in the top level list becomes a table row and each item in the second level list becomes a table cell, while third level list remain lists. Note also that the filter handles the situation where there are only two items in the second second-level list: if any rows are shorter than the longest row they are padded with empty cells towards the end.

### Headerless tables

To turn a list of lists into a headerless table just include the class `no-header` (or `noheader`) on the wrapping div:

````pandoc
::: {.lol2table}
Table with header

1.  1.  foo
    2.  bar
    3.  baz

2.  1.  tic
    2.  tac
    3.  toc
:::

::: {.lol2table .no-header}
Table without header

1.  1.  foo
    2.  bar
    3.  baz

2.  1.  tic
    2.  tac
    3.  toc
:::
````

````pandoc
foo   bar   baz
----- ----- -----
tic   tac   toc

: Table with header

----- ----- -----
foo   bar   baz
tic   tac   toc
----- ----- -----

: Table without header
````

### Captions

The previous example also shows how to set a caption on the table: just include a paragraph with the caption text inside the div.

### Custom alignments and custom column widths

To specify the alignment of the table columns set an attribute `align` on the div.  Its value should be a comma separated "list" (and I mean *comma* separated, not comma-and-whitespace!) of any of the letters `d l c r` (for `AlignDefault`, `AlignLeft`, `AlignCenter`, `AlignRight` respectively):

````pandoc
::: {.lol2table align="l,c,r"}
*   -   foo
    -   bar
    -   baz
*   -   +   tic
        +   pic
    -   +   tac
        +   pac
:::
````

````pandoc
+---------+---------+-----+
| foo     | bar     | baz |
+:========+:=======:+====:+
| -   tic | -   tac |     |
| -   pic | -   pac |     |
+---------+---------+-----+
````

Likewise to specify the relative width of columns include an attribute `widths` on the div.  Its value should be a comma-separated (again really *comma* separated!) "list" of integers between 0 and 100, where each integer is the percentage of the available total width which should be the width of the respective column:

````pandoc
::: {.lol2table widths="20,40,10"}
*   -   foo
    -   bar
    -   baz
*   -   +   tic
        +   pic
    -   +   tac
        +   pac
:::
````

````pandoc
+-------------+---------------------------+------+
| foo         | bar                       | baz  |
+=============+===========================+======+
| -   tic     | -   tac                   |      |
| -   pic     | -   pac                   |      |
+-------------+---------------------------+------+
````

Naturally you can combine the two:

````pandoc
::: {.lol2table align="l,c,r" widths="20,40,10"}
*   -   foo
    -   bar
    -   baz
*   -   tic
    -   tac
:::
````

````pandoc
---------------------------------------------------
foo                        bar                  baz
-------------- ---------------------------- -------
tic                        tac              

---------------------------------------------------
````

If you specify more alignments or widths than there are columns the extra alignments/widths will be ignored.

If you specify fewer alignments than there are columns the list of alignments is padded to the right length with copies of the rightmost alignment actually specified.  If you specify fewer widths than there are columns the list of widths is padded to the right length with zeroes.  This should cause Pandoc to distribute the remaining width between them.

## Roundtripping

To convert a table into a list of lists you wrap it in a div with the class `table2lol`:

````pandoc
:::table2lol

|foo|bar|baz
|---|---|---
|tic|tac|toc

:::
````

````pandoc
0.  1.  foo
    2.  bar
    3.  baz

1.  1.  tic
    2.  tac
    3.  toc
````

Note that the resulting lists always are numbered lists and that if there was a header row the numbering of the top-level list starts at zero.

### Keeping the div

If you include a class `keep-div` (or `keepdiv`) on the div the result will also be wrapped in a div, designed to make roundtripping easier:


````pandoc
::: {#alpha .lol2table .keep-div}
1.  1.  foo
    2.  bar
    3.  baz
2.  1.  tic
    2.  tac
    3.  toc
:::

::: {#beta .table2lol .keep-div}
  foo   bar   baz
  ----- ----- -----
  tic   tac   toc
:::
````

::: {#alpha .maybe-table2lol .keep-div}
  foo   bar   baz
  ----- ----- -----
  tic   tac   toc
:::

::: {#beta .maybe-lol2table .keep-div align="l,l,l" widths="0,0,0"}
0.  1.  foo
    2.  bar
    3.  baz

1.  1.  tic
    2.  tac
    3.  toc
:::

## Author

Benct Philip Jonsson `bpjonsson+pandoc@gmail.com`

## Copyright and license

This software is Copyright (c) 2020 by Benct Philip Jonsson.

This is free software, licensed under:

  The MIT (X11) License

http://www.opensource.org/licenses/mit-license.php
