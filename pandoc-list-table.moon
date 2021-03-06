
filter_info = [==========[
This is filter version 202010012000

This software is Copyright (c) 2020 by Benct Philip Jonsson.

This is free software, licensed under:

  The MIT (X11) License

http://www.opensource.org/licenses/mit-license.php
]==========]

import concat, insert, remove, pack, unpack from table
import floor from math

assertion = (msg, val) -> assert val, msg

-- Check if we have SimpleTable
SimpleTable = pandoc.SimpleTable
Table = SimpleTable or pandoc.Table

unless 'function' == type SimpleTable
  if pandoc.types and PANDOC_VERSION
    Version = pandoc.types.Version
    -- If Version isn't a function Pandoc is surely less than 2.10
    if 'function' == type Version
      -- We know we haven't got SimpleTable, so now check if Pandoc < 2.10
      assertion "The pandoc-list-table filter does not work with Pandoc #{PANDOC_VERSION}",
        PANDOC_VERSION < Version '2.10.0'

-- pcall with less boilerplate
call_func = (id, ...) ->
  res = pack pcall ...
  assert res[1], "Error #{id}: #{res[2]}"
  remove res, 1
  return unpack res

-- contains_any(val1 [, val2, ...])
  -- returns a closure such that closure(x) returns
  --  * nil if x is not a table
  --  * true if x is an array and contains a value
  --    which is equal to one of val1, ...
  --  * false otherwise
contains_any = (...) ->
  wanted = {w, true for w in *pack ...}
  return (list) ->
    switch type list
      when 'table'
        for v in *list
          if wanted[v]
            return true
      else
        return nil
    return false

-- is_elem(val, tag1 [, tag2, ...])
  -- returns
  --  * false if x is not a table
  --  * false if x.tag is not a string
  --  * x.tag if x.tag equals one of tag1, ...
  --  * nil otherwise
-- is_elem(x)
  -- returns
  --  * false if x is not a table
  --  * false if x.tag is not a string
  --  * true otherwise
is_elem = (x, ...) ->
  switch type x
    when 'table'
      tag = x.tag
      switch type tag
        when 'string'
          tags = pack ...
          if #tags > 0
            for t in *tags
              if t == tag
                return tag
            return nil
          return true
      return false

-- get_div_id(cls, div [, div_count])
  --
  -- Takes the following arguments:
  --
  -- 1.  A string. May be a class name, something else which
  --    migh serve as a "div type", or an empty string.
  --
  -- 2.  An actual Pandoc Div object.
  --
  -- 3.  An optional number, assumed to be the number of divs of
  --     the same "type" already seen, including the current
  --     one.
  --
  -- Returns a string of the form `<cls> div #<id>`, where
  -- `<id>` is either the id attribute of `div`, or if
  -- that is empty the `div_count`.

get_div_id = (cls, div, div_count="") ->
  div_id = div.identifier or ""
  div_id = div_count if "" == div_id
  return "#{cls} div ##{div_id}"

-- Map one-letter abbreviations to full alignment type names.
letter2align = {
  d: 'AlignDefault'
  l: 'AlignLeft'
  c: 'AlignCenter'
  r: 'AlignRight'
}
-- Map full alignment type names to one-letter abbreviations.
align2letter = {v,k for k,v in pairs letter2align}

-- Functions to look for variants of the 'magic' classes.
contains_no_header = contains_any 'no-header', 'noheader'
contains_keep_div = contains_any 'keep-div', 'keepdiv'

-- Function to convert a list of lists to a table
lol2table = do
  -- Keep track of how many lol2table divs we have seen.
  div_count = 0
  -- The function receives the enclosing div as argument
  (div) ->
    -- Increment the count
    div_count += 1
    -- Get a moniker for this div
    div_id = get_div_id 'lol2table', div, div_count
    -- Now look up the LoL and the caption paragraph if any.
    -- Start by declaring the variables
    lol, caption = nil, nil
    -- Now loop through the children of the div:
    for item in *div.content
      continue unless is_elem item -- can't happen!
      -- See what kind of element we got
      switch item.tag
        when 'BulletList', 'OrderedList'
          -- Complain if we already saw a list
          if lol
            error "Expected only one list in #{div_id}", 2
          lol = item
        when 'Para', 'Plain'
          -- Complain if we already saw a paragraph
          if caption
            error "Expected only one caption paragraph in #{div_id}", 2
          caption = item.content
        else
          -- Complain if we see something other than a list or para
          error "Didn't expect #{item.tag} in #{div_id}", 2
    -- Abort if we didn't see any list
    return nil unless lol
    -- The caption defaults to an empty list
    caption or= {}
    -- This can't really happen, so why is this check there?
    unless is_elem lol, 'BulletList', 'OrderedList'
      return nil
    -- Do we want a table with a header?
    header = not( contains_no_header div.classes )
    -- Init the array of rows
    rows = {}
    -- Init the column count
    col_count = 0
    -- Loop through the list items
    for item in *lol.content
      -- Check that the item contains a list and nothing else
      assertion "Expected list in #{div_id} to be list of lists",
        #item == 1 and is_elem item[1], 'BulletList', 'OrderedList'
      -- The items of the inner list are the next table row
      row = item[1].content
      -- If this row is longer than any seen before
      -- we update the column count
      if #row > col_count
        col_count = #row
      rows[#rows+1] = row
    -- Make sure all rows are the same length by adding empty
    -- cells until they are the same length as the longest row
    for row in *rows
      while #row < col_count
        row[#row+1] = {}
    -- If we want a header use the first row,
    -- else set the headers to an empty list
    headers = if header
      remove rows, 1
    else
      {}
    -- Init the list of aligns
    aligns = {}
    -- Get the align attribute if any and coerce it to lowercase
    align = (div.attributes.align or "")\lower!
    -- If the align attr is empty it defaults to a single d
    align = 'd' if "" == align
    -- Now step through the comma-separated "items"
    for a in align\gmatch '[^,]+'
      -- Check that we have a valid "align-letter" and
      -- append its expansion to the list of aligns
      aligns[#aligns+1] = assertion "Unknown column alignment in #{div_id}: '#{a}'",
        letter2align[a]
      -- Don't look any further if we got the right number of aligns
      if #aligns == col_count
        break
    -- If we got too few aligns pad out with copies of the last
    while #aligns < col_count
      aligns[#aligns+1] = aligns[#aligns]
    -- Now do the same with widths
    widths = {}
    width = div.attributes.widths or ""
    -- Widths default to automatic widths
    width = '0' if "" == width
    for w in width\gmatch '[^,]+'
      -- A width is a percentage of the available total width,
      -- tableso an integer with up to three digits
      assertion "Expected column width in #{div_id} to be percentage, not '#{w}'",
        w\match '^[01]?%d?%d$'
      -- Convert it to a float and append it to the
      -- list of widths
      widths[#widths+1] = tonumber(w, 10) / 100
      if #widths == col_count
        break
    while #widths < col_count
      -- Pad with auto widths if we got too few widths
      widths[#widths+1] = 0
    -- See if we can create a table
    -- and give a nice error message if we fail
    tab = call_func "converting  list to table in #{div_id}", Table, caption, aligns, widths, headers, rows
    if SimpleTable and 'SimpleTable' == tab.tag
      tab = call_func "converting SimpleTable to Table in #{div_id}",
        pandoc.utils.from_simple_table, tab
    -- Do we want to keep the div?
    if contains_keep_div div.classes
      -- Reuse the attrs of the old div as far as possible!
      attr = div.attr
      -- Remove any old align/widths attrs since they may
      -- become inaccurate if the table is altered.
      for key in *{'align', 'widths'}
        attr.attributes[key] = nil
      -- Remove the lol2table class which certainly is
      -- wrong now
      attr.classes = [c for c in *div.classes when 'lol2table' != c]
      -- but make it easy for the user to revert to a LoL
      -- should they want to!
      insert attr.classes, 1, 'maybe-table2lol'
      -- Return a div with the table and the attributes
      return pandoc.Div {tab}, attr
    -- Else don't keep the div, just return the table!
    return tab

table2lol = do
  no_class = table2lol: true, 'no-header': true, noheader: true
  div_count = 0
  (div) ->
    div_count += 1
    return nil if #div.content == 0
    div_id = get_div_id 'table2lol', div, div_count
    assertion "Expected #{div_id} to contain only a table",
      #div.content == 1 and is_elem div.content[1], 'Table', 'SimpleTable'
    tab = div.content[1]
    if SimpleTable and 'SimpleTable' ~= tab.tag
      tab = call_func "converting Table to SimpleTable in #{div_id}",
        pandoc.utils.to_simple_table, tab
    caption, headers, rows = tab.caption, tab.headers, tab.rows
    header = false
    for h in *headers
      header = true if #h > 0
    lol = [ {pandoc.OrderedList(row)} for row in *rows ]
    list_attr = pandoc.ListAttributes!
    if header
      insert lol, 1, {pandoc.OrderedList(headers)}
      list_attr.start = 0
    lol = pandoc.OrderedList lol, list_attr
    if contains_keep_div div.classes
      cols = {
        align:  [align2letter[a] for a in *tab.aligns]
        widths: [floor(w * 100) for w in *tab.widths]
      }
      classes = [ c for c in *div.classes when not no_class[c] ]
      caption = if #caption > 0
        pandoc.Para caption
      else
        pandoc.Null!
      unless header
        insert classes, 1, 'no-header'
      insert classes, 1, 'maybe-lol2table'
      attr = div.attr
      attr.classes = classes
      for key, list in pairs cols
        attr.attributes[key] = concat list, ","
      return pandoc.Div {lol, caption}, attr
    return lol





return do
  div_count = 0
  {
    {
      Div: =>
        div_count += 1
        is_lol2table = @classes\includes 'lol2table'
        is_table2lol = @classes\includes 'table2lol'
        if is_lol2table and is_table2lol
          div_id = get_div_id "", @, div_count
          error "Expected#{div_id} to have class .lol2table or class .table2lol, not both"
        elseif is_lol2table
          return lol2table @
        elseif is_table2lol
          return table2lol @
        return nil
    }
  }

