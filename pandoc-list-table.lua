local filter_info = [==========[This is filter version 20201124

This software is Copyright (c) 2020 by Benct Philip Jonsson.

This is free software, licensed under:

  The MIT (X11) License

http://www.opensource.org/licenses/mit-license.php
]==========]
local concat, insert, remove, pack, unpack
do
  local _obj_0 = table
  concat, insert, remove, pack, unpack = _obj_0.concat, _obj_0.insert, _obj_0.remove, _obj_0.pack, _obj_0.unpack
end
local floor
floor = math.floor
local assertion
assertion = function(msg, val)
  assert(val, msg)
  return val
end
local SimpleTable = pandoc.SimpleTable
local Table = SimpleTable or pandoc.Table
if not ('function' == type(SimpleTable)) then
  if pandoc.types and PANDOC_VERSION then
    local Version = pandoc.types.Version
    if 'function' == type(Version) then
      assertion("The pandoc-list-table filter does not work with Pandoc " .. tostring(PANDOC_VERSION), PANDOC_VERSION < Version('2.10.0'))
    end
  end
end
local call_func
call_func = function(id, ...)
  local res = pack(pcall(...))
  assert(res[1], "Error " .. tostring(id) .. ": " .. tostring(res[2]))
  remove(res, 1)
  return unpack(res)
end
local keys_of
keys_of = function(self)
  assertion("Not a table: " .. tostring(type(self)) .. " " .. tostring(self), 'table' == type(self))
  local _accum_0 = { }
  local _len_0 = 1
  for k in pairs(self) do
    _accum_0[_len_0] = k
    _len_0 = _len_0 + 1
  end
  return _accum_0
end
local round
round = function(x)
  x = assertion("Not a number: " .. tostring(x), tonumber(x))
  return floor(x + 0.5)
end
local contains_any
contains_any = function(...)
  local wanted
  do
    local _tbl_0 = { }
    local _list_0 = pack(...)
    for _index_0 = 1, #_list_0 do
      local w = _list_0[_index_0]
      _tbl_0[w] = true
    end
    wanted = _tbl_0
  end
  return function(list)
    local _exp_0 = type(list)
    if 'table' == _exp_0 then
      for _index_0 = 1, #list do
        local v = list[_index_0]
        if wanted[v] then
          return true
        end
      end
    else
      return nil
    end
    return false
  end
end
local is_elem
is_elem = function(x, ...)
  local _exp_0 = type(x)
  if 'table' == _exp_0 then
    local tag = x.tag
    local _exp_1 = type(tag)
    if 'string' == _exp_1 then
      local tags = pack(...)
      if #tags > 0 then
        for _index_0 = 1, #tags do
          local t = tags[_index_0]
          if t == tag then
            return tag
          end
        end
        return nil
      end
    end
    return true
  end
  return false
end
local list_attributes
list_attributes = function(self)
  assertion("Not a table: " .. tostring(type(self)) .. " " .. tostring(self), 'table' == type(self))
  return pandoc.ListAttributes(unpack(self))
end
local get_value
get_value = function(...)
  local keys = pack(...)
  assertion("Expected one or more key names as arguments", #keys > 0)
  return function(self)
    if not ('table' == type(self)) then
      return nil
    end
    for _index_0 = 1, #keys do
      local k = keys[_index_0]
      if self[k] then
        return self[k]
      end
    end
    return nil
  end
end
local remove_fields
remove_fields = function(...)
  local keys = pack(...)
  assertion("Expekted one or more field keys as arguments", #keys > 0)
  return function(self)
    assertion("Not a table: " .. tostring(type(self)) .. " " .. tostring(self), 'table' == type(self))
    for _index_0 = 1, #keys do
      local k = keys[_index_0]
      self[k] = nil
    end
    return k
  end
end
local get_div_id
get_div_id = function(cls, div, div_count)
  if div_count == nil then
    div_count = ""
  end
  local div_id = div.identifier or ""
  if "" == div_id then
    div_id = div_count
  end
  return tostring(cls) .. " div #" .. tostring(div_id)
end
local letter2align = {
  d = 'AlignDefault',
  l = 'AlignLeft',
  c = 'AlignCenter',
  r = 'AlignRight'
}
local align2letter
do
  local _tbl_0 = { }
  for k, v in pairs(letter2align) do
    _tbl_0[v] = k
  end
  align2letter = _tbl_0
end
local contains_no_header = contains_any('no-header', 'noheader', 'no_header', 'noHeader')
local contains_keep_div = contains_any('keep-div', 'keepdiv', 'keep_div', 'keepDiv')
local get = {
  align = {
    'aligns',
    'align',
    'alignments',
    'alignment'
  },
  widths = {
    'widths',
    'width'
  },
  list_start = {
    'list-start',
    'liststart',
    'list_start',
    'listStart'
  },
  sublist_start = {
    'sublist-start',
    'subliststart',
    'sublist_start',
    'sublistStart'
  }
}
local remove_attrs
do
  local attrs
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _, v in pairs(get) do
      for _index_0 = 1, #v do
        local a = v[_index_0]
        _accum_0[_len_0] = a
        _len_0 = _len_0 + 1
      end
    end
    attrs = _accum_0
  end
  remove_attrs = remove_fields(unpack(attrs))
end
local _list_0 = keys_of(get)
for _index_0 = 1, #_list_0 do
  local a = _list_0[_index_0]
  get[a] = get_value(unpack(get[a]))
end
local lol2table
do
  local div_count = 0
  lol2table = function(div)
    div_count = div_count + 1
    local div_id = get_div_id('lol2table', div, div_count)
    local lol, caption = nil, nil
    local _list_1 = div.content
    for _index_0 = 1, #_list_1 do
      local _continue_0 = false
      repeat
        local item = _list_1[_index_0]
        if not (is_elem(item)) then
          _continue_0 = true
          break
        end
        local _exp_0 = item.tag
        if 'BulletList' == _exp_0 or 'OrderedList' == _exp_0 then
          if lol then
            error("Expected only one list in " .. tostring(div_id), 2)
          end
          lol = item
        elseif 'Para' == _exp_0 or 'Plain' == _exp_0 then
          if caption then
            error("Expected only one caption paragraph in " .. tostring(div_id), 2)
          end
          caption = item.content
        else
          error("Didn't expect " .. tostring(item.tag) .. " in " .. tostring(div_id))
        end
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    if not (lol) then
      return nil
    end
    caption = caption or { }
    if not (is_elem(lol, 'BulletList', 'OrderedList')) then
      return nil
    end
    local header = not (contains_no_header(div.classes))
    local rows = { }
    local col_count = 0
    local _list_2 = lol.content
    for _index_0 = 1, #_list_2 do
      local item = _list_2[_index_0]
      assertion("Expected list in " .. tostring(div_id) .. " to be list of lists", (#item == 1) and is_elem(item[1], 'BulletList', 'OrderedList'))
      local row = item[1].content
      if #row > col_count then
        col_count = #row
      end
      rows[#rows + 1] = row
    end
    for _index_0 = 1, #rows do
      local row = rows[_index_0]
      while #row < col_count do
        row[#row + 1] = { }
      end
    end
    local headers
    if header then
      headers = remove(rows, 1)
    else
      headers = { }
    end
    local aligns = { }
    local align = (get.align(div.attributes) or ""):lower()
    if "" == align then
      align = 'd'
    end
    for a in align:gmatch('[^,]+') do
      aligns[#aligns + 1] = assertion("Unknown column alignment in " .. tostring(div_id) .. ": '" .. tostring(a) .. "'", letter2align[a])
      if #aligns == col_count then
        break
      end
    end
    while #aligns < col_count do
      aligns[#aligns + 1] = aligns[#aligns]
    end
    local widths = { }
    local width = get.widths(div.attributes) or ""
    if "" == width then
      width = '0'
    end
    for w in width:gmatch('[^,]+') do
      assertion("Expected column width in " .. tostring(div_id) .. " to be percentage, not '" .. tostring(w) .. "'", w:match('^[01]?%d?%d$'))
      widths[#widths + 1] = tonumber(w, 10) / 100
      if #widths == col_count then
        break
      end
    end
    while #widths < col_count do
      widths[#widths + 1] = 0
    end
    local tab = call_func("converting  list to table in " .. tostring(div_id), Table, caption, aligns, widths, headers, rows)
    if SimpleTable and 'SimpleTable' == tab.tag then
      tab = call_func("converting SimpleTable to Table in " .. tostring(div_id), pandoc.utils.from_simple_table, tab)
    end
    if contains_keep_div(div.classes) then
      local attr = div.attr
      do
        local sublist_start = get.sublist_start(attr.attributes)
        remove_attrs(attr.attributes)
        attr.attributes['sublist-start'] = sublist_start
      end
      do
        local _accum_0 = { }
        local _len_0 = 1
        local _list_3 = div.classes
        for _index_0 = 1, #_list_3 do
          local c = _list_3[_index_0]
          if 'lol2table' ~= c then
            _accum_0[_len_0] = c
            _len_0 = _len_0 + 1
          end
        end
        attr.classes = _accum_0
      end
      insert(attr.classes, 1, 'maybe-table2lol')
      if 'OrderedList' == lol.tag then
        attr.attributes['start-num'] = lol.start
      end
      return pandoc.Div({
        tab
      }, attr)
    end
    return tab
  end
end
local table2lol
do
  local no_class = {
    table2lol = true,
    ['no-header'] = true,
    noheader = true
  }
  local div_count = 0
  table2lol = function(div)
    div_count = div_count + 1
    if #div.content == 0 then
      return nil
    end
    local div_id = get_div_id('table2lol', div, div_count)
    assertion("Expected " .. tostring(div_id) .. " to contain only a table", (#div.content == 1) and is_elem(div.content[1], 'Table', 'SimpleTable'))
    local tab = div.content[1]
    if SimpleTable and 'SimpleTable' ~= tab.tag then
      tab = call_func("converting Table to SimpleTable in " .. tostring(div_id), pandoc.utils.to_simple_table, tab)
    end
    local caption, headers, rows = tab.caption, tab.headers, tab.rows
    local header = false
    for _index_0 = 1, #headers do
      local h = headers[_index_0]
      if #h > 0 then
        header = true
      end
    end
    local list_attr = {
      get.list_start(div.attributes)
    }
    local sublist_attr = {
      get.sublist_start(div.attributes)
    }
    local lol
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #rows do
        local row = rows[_index_0]
        _accum_0[_len_0] = {
          pandoc.OrderedList(row, list_attributes(sublist_attr))
        }
        _len_0 = _len_0 + 1
      end
      lol = _accum_0
    end
    if header then
      insert(lol, 1, {
        pandoc.OrderedList(headers, list_attributes(sublist_attr))
      })
      list_attr.start = list_attr.start or 0
    end
    lol = pandoc.OrderedList(lol, list_attributes(list_attr))
    if contains_keep_div(div.classes) then
      local cols = {
        align = (function()
          local _accum_0 = { }
          local _len_0 = 1
          local _list_1 = tab.aligns
          for _index_0 = 1, #_list_1 do
            local a = _list_1[_index_0]
            _accum_0[_len_0] = align2letter[a]
            _len_0 = _len_0 + 1
          end
          return _accum_0
        end)(),
        widths = (function()
          local _accum_0 = { }
          local _len_0 = 1
          local _list_1 = tab.widths
          for _index_0 = 1, #_list_1 do
            local w = _list_1[_index_0]
            _accum_0[_len_0] = round(w * 100)
            _len_0 = _len_0 + 1
          end
          return _accum_0
        end)()
      }
      set_attrs({
        ['list-start'] = get.list_start(div.attributes),
        ['sublist-start'] = get.sublist_start(div.attributes)
      })
      local classes
      do
        local _accum_0 = { }
        local _len_0 = 1
        local _list_1 = div.classes
        for _index_0 = 1, #_list_1 do
          local c = _list_1[_index_0]
          if not no_class[c] then
            _accum_0[_len_0] = c
            _len_0 = _len_0 + 1
          end
        end
        classes = _accum_0
      end
      if #caption > 0 then
        caption = pandoc.Para(caption)
      else
        caption = pandoc.Null()
      end
      if not (header) then
        insert(classes, 1, 'no-header')
      end
      insert(classes, 1, 'maybe-lol2table')
      local attr = div.attr
      remove_attrs(attr.attributes)
      attr.classes = classes
      for key, list in pairs(cols) do
        attr.attributes[key] = concat(list, ",")
      end
      for key, val in pairs(set_attrs) do
        attr.attributes[key] = val
      end
      return pandoc.Div({
        lol,
        caption
      }, attr)
    end
    return lol
  end
end
do
  local div_count = 0
  return {
    {
      Div = function(self)
        div_count = div_count + 1
        local is_lol2table = self.classes:includes('lol2table')
        local is_table2lol = self.classes:includes('table2lol')
        if is_lol2table and is_table2lol then
          local div_id = get_div_id("", self, div_count)
          error("Expected" .. tostring(div_id) .. " to have class .lol2table or class .table2lol, not both")
        elseif is_lol2table then
          return lol2table(self)
        elseif is_table2lol then
          return table2lol(self)
        end
        return nil
      end
    }
  }
end
