-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local L = locale.localize
local gui = gui

-- Helper function for printing messages to buffers.
-- @see gui._print
local function _print(buffer_type, ...)
  if buffer._type ~= buffer_type then
    for i, view in ipairs(_VIEWS) do
      if view.buffer._type == buffer_type then gui.goto_view(i) break end
    end
    if view.buffer._type ~= buffer_type then
      view:split()
      for i, buffer in ipairs(_BUFFERS) do
        if buffer._type == buffer_type then view:goto_buffer(i) break end
      end
      if buffer._type ~= buffer_type then
        new_buffer()._type = buffer_type
        events.emit(events.FILE_OPENED)
      end
    end
  end
  local args, n = {...}, select('#', ...)
  for i = 1, n do args[i] = tostring(args[i]) end
  buffer:append_text(table.concat(args, '\t'))
  buffer:append_text('\n')
  buffer:goto_pos(buffer.length)
  buffer:set_save_point()
end
-- LuaDoc is in core/.gui.luadoc.
function gui._print(buffer_type, ...) pcall(_print, buffer_type, ...) end

-- LuaDoc is in core/.gui.luadoc.
function gui.print(...) gui._print(L('[Message Buffer]'), ...) end

-- LuaDoc is in core/.gui.luadoc.
function gui.filteredlist(title, columns, items, int_return, ...)
  local out = gui.dialog('filteredlist',
                         '--title', title,
                         '--button1', 'gtk-ok',
                         '--button2', 'gtk-cancel',
                         '--no-newline',
                         int_return and '' or '--string-output',
                         '--columns', columns,
                         '--items', items,
                         ...)
  local patt = int_return and '^(%-?%d+)\n(%d+)$' or '^([^\n]+)\n(.+)$'
  local response, value = out:match(patt)
  if response == (int_return and '1' or 'gtk-ok') then
    return not int_return and value or tonumber(value)
  end
end

-- LuaDoc is in core/.gui.luadoc.
function gui.switch_buffer()
  local columns, items = { L('Name'), L('File') }, {}
  for _, buffer in ipairs(_BUFFERS) do
    local filename = buffer.filename or buffer._type or L('Untitled')
    items[#items + 1] = (buffer.dirty and '*' or '')..filename:match('[^/\\]+$')
    items[#items + 1] = filename
  end
  local i = gui.filteredlist(L('Switch Buffers'), columns, items, true)
  if i then view:goto_buffer(i + 1) end
end

-- LuaDoc is in core/.gui.luadoc.
function gui.goto_file(filename, split, preferred_view)
  if #_VIEWS == 1 and view.buffer.filename ~= filename and split then
    view:split()
  else
    local other_view = _VIEWS[preferred_view]
    for i, v in ipairs(_VIEWS) do
      if v.buffer.filename == filename then gui.goto_view(i) return end
      if not other_view and v ~= view then other_view = i end
    end
    if other_view then gui.goto_view(other_view) end
  end
  io.open_file(filename)
end

local THEME
-- LuaDoc is in core/.gui.luadoc.
function gui.set_theme(name)
  if not name then
    -- Read theme from ~/.textadept/theme, defaulting to 'light'.
    local f = io.open(_USERHOME..'/theme', 'rb')
    if f then
      name = f:read('*line'):match('[^\r\n]+')
      f:close()
    end
    if not name or name == '' then name = 'light' end
  end

  -- Get the path of the theme.
  local theme
  if not name:find('[/\\]') then
    if lfs.attributes(_USERHOME..'/themes/'..name) then
      theme = _USERHOME..'/themes/'..name
    elseif lfs.attributes(_HOME..'/themes/'..name) then
      theme = _HOME..'/themes/'..name
    end
  elseif lfs.attributes(name) then
    theme = name
  end
  if not theme then error(('"%s" %s'):format(name, L("theme not found."))) end

  if buffer and view then
    local current_buffer, current_view = _BUFFERS[buffer], _VIEWS[view]
    for i in ipairs(_BUFFERS) do
      view:goto_buffer(i)
      buffer.property['lexer.lpeg.color.theme'] = theme..'/lexer.lua'
      local lexer = buffer:get_lexer()
      buffer:set_lexer('null') -- lexer needs to be changed to reset styles
      buffer:set_lexer(lexer)
      local ok, err = pcall(dofile, theme..'/buffer.lua')
      if not ok then io.stderr:write(err) end
    end
    view:goto_buffer(current_buffer)
    for i in ipairs(_VIEWS) do
      gui.goto_view(i)
      local lexer = buffer:get_lexer()
      buffer:set_lexer('null') -- lexer needs to be changed to reset styles
      buffer:set_lexer(lexer)
      local ok, err = pcall(dofile, theme..'/view.lua')
      if not ok then io.stderr:write(err) end
    end
    gui.goto_view(current_view)
  end
  THEME = theme
end

-- LuaDoc is in core/.gui.luadoc.
function gui.select_theme()
  local themes, themes_found = {}, {}
  for theme in lfs.dir(_HOME..'/themes') do
    if not theme:find('^%.%.?$') then themes_found[theme] = true end
  end
  if lfs.attributes(_USERHOME..'/themes') then
    for theme in lfs.dir(_USERHOME..'/themes') do
      if not theme:find('^%.%.?$') then themes_found[theme] = true end
    end
  end
  for theme in pairs(themes_found) do themes[#themes + 1] = theme end
  table.sort(themes)
  local theme = gui.filteredlist(L('Select Theme'), L('Name'), themes)
  if theme then gui.set_theme(theme) end
end

local connect = events.connect

-- Sets default properties for a Scintilla window.
connect(events.VIEW_NEW, function()
  local buffer = buffer
  local c = _SCINTILLA.constants

  -- Allow redefinitions of these Scintilla key commands.
  local ctrl_keys = {
    '[', ']', '/', '\\', 'Z', 'Y', 'X', 'C', 'V', 'A', 'L', 'T', 'D', 'U'
  }
  local ctrl_shift_keys = { 'L', 'T', 'U', 'Z' }
  for _, key in ipairs(ctrl_keys) do
    buffer:clear_cmd_key(string.byte(key), c.SCMOD_CTRL)
  end
  for _, key in ipairs(ctrl_shift_keys) do
    buffer:clear_cmd_key(string.byte(key), c.SCMOD_CTRL + c.SCMOD_SHIFT)
  end
  -- Load theme.
  local ok, err = pcall(dofile, THEME..'/view.lua')
  if not ok then io.stderr:write(err) end
end)
connect(events.VIEW_NEW, function() events.emit(events.UPDATE_UI) end)

local SETDIRECTFUNCTION = _SCINTILLA.properties.direct_function[1]
local SETDIRECTPOINTER = _SCINTILLA.properties.doc_pointer[2]
local SETLEXERLANGUAGE = _SCINTILLA.functions.set_lexer_language[1]
local function set_properties()
  local buffer = buffer
  -- Lexer.
  buffer:set_lexer_language('lpeg')
  buffer:private_lexer_call(SETDIRECTFUNCTION, buffer.direct_function)
  buffer:private_lexer_call(SETDIRECTPOINTER, buffer.direct_pointer)
  buffer:private_lexer_call(SETLEXERLANGUAGE, 'container')
  buffer.style_bits = 8
  -- Properties.
  buffer.property['textadept.home'] = _HOME
  buffer.property['lexer.lpeg.home'] = _LEXERPATH
  buffer.property['lexer.lpeg.script'] = _HOME..'/lexers/lexer.lua'
  buffer.property['lexer.lpeg.color.theme'] = THEME..'/lexer.lua'
  -- Buffer.
  buffer.code_page = _SCINTILLA.constants.SC_CP_UTF8
  -- Load theme.
  local ok, err = pcall(dofile, THEME..'/buffer.lua')
  if not ok then io.stderr:write(err) end
end

-- Sets default properties for a Scintilla document.
connect(events.BUFFER_NEW, function()
  -- Normally when an error occurs, a new buffer is created with the error
  -- message, but if an error occurs here, this event would be called again and
  -- again, erroring each time resulting in an infinite loop; print error to
  -- stderr instead.
  local ok, err = pcall(set_properties)
  if not ok then io.stderr:write(err) end
end)
connect(events.BUFFER_NEW, function() events.emit(events.UPDATE_UI) end)

-- Sets the title of the Textadept window to the buffer's filename.
-- @param buffer The global buffer.
local function set_title(buffer)
  local filename = buffer.filename or buffer._type or L('Untitled')
  gui.title = string.format('%s %s Textadept (%s)', filename:match('[^/\\]+$'),
                            buffer.dirty and '*' or '-', filename)
end

-- Changes Textadept title to show the buffer as being "clean".
connect(events.SAVE_POINT_REACHED, function()
  buffer.dirty = false
  set_title(buffer)
end)

-- Changes Textadept title to show thee buffer as "dirty".
connect(events.SAVE_POINT_LEFT, function()
  buffer.dirty = true
  set_title(buffer)
end)

-- Open uri(s).
connect(events.URI_DROPPED, function(utf8_uris)
  for utf8_uri in utf8_uris:gmatch('[^\r\n]+') do
    if utf8_uri:find('^file://') then
      utf8_uri = utf8_uri:match('^file://([^\r\n]+)')
      utf8_uri = utf8_uri:gsub('%%(%x%x)', function(hex)
        return string.char(tonumber(hex, 16))
      end)
      if WIN32 then utf8_uri = utf8_uri:sub(2, -1) end -- ignore leading '/'
      local uri = utf8_uri:iconv(_CHARSET, 'UTF-8')
      if lfs.attributes(uri).mode ~= 'directory' then io.open_file(utf8_uri) end
    end
  end
end)
connect(events.APPLEEVENT_ODOC,
  function(uri) return events.emit(events.URI_DROPPED, 'file://'..uri) end)

local string_format = string.format
local EOLs = { L('CRLF'), L('CR'), L('LF') }
local GETLEXERLANGUAGE = _SCINTILLA.functions.get_lexer_language[1]
-- Sets docstatusbar text.
connect(events.UPDATE_UI, function()
  local buffer = buffer
  local pos = buffer.current_pos
  local line, max = buffer:line_from_position(pos) + 1, buffer.line_count
  local col = buffer.column[pos] + 1
  local lexer = buffer:private_lexer_call(GETLEXERLANGUAGE)
  local eol = EOLs[buffer.eol_mode + 1]
  local tabs = string_format('%s %d', buffer.use_tabs and L('Tabs:') or
                             L('Spaces:'), buffer.indent)
  local enc = buffer.encoding or ''
  gui.docstatusbar_text =
    string_format('%s %d/%d    %s %d    %s    %s    %s    %s', L('Line:'), line,
                  max, L('Col:'), col, lexer, eol, tabs, enc)
end)

-- Toggles folding.
connect(events.MARGIN_CLICK, function(margin, pos, modifiers)
  if margin == 2 then buffer:toggle_fold(buffer:line_from_position(pos)) end
end)

connect(events.BUFFER_NEW, function() set_title(buffer) end)

-- Save buffer properties.
connect(events.BUFFER_BEFORE_SWITCH, function()
  local buffer = buffer
  -- Save view state.
  buffer._anchor, buffer._current_pos = buffer.anchor, buffer.current_pos
  buffer._first_visible_line = buffer.first_visible_line
  -- Save fold state.
  buffer._folds = {}
  local folds = buffer._folds
  local i = buffer:contracted_fold_next(0)
  while i >= 0 do
    folds[#folds + 1] = i
    i = buffer:contracted_fold_next(i + 1)
  end
end)

-- Restore buffer properties.
connect(events.BUFFER_AFTER_SWITCH, function()
  local buffer = buffer
  if not buffer._folds then return end
  -- Restore fold state.
  for _, i in ipairs(buffer._folds) do buffer:toggle_fold(i) end
  -- Restore view state.
  buffer:set_sel(buffer._anchor, buffer._current_pos)
  buffer:line_scroll(0,
                     buffer:visible_from_doc_line(buffer._first_visible_line) -
                     buffer.first_visible_line)
end)

-- Updates titlebar and statusbar.
connect(events.BUFFER_AFTER_SWITCH, function()
  set_title(buffer)
  events.emit(events.UPDATE_UI)
end)

-- Updates titlebar and statusbar.
connect(events.VIEW_AFTER_SWITCH, function()
  set_title(buffer)
  events.emit(events.UPDATE_UI)
end)

connect(events.RESET_AFTER, function() gui.statusbar_text = 'Lua reset' end)

-- Prompts for confirmation if any buffers are dirty.
connect(events.QUIT, function()
  local list = {}
  for _, buffer in ipairs(_BUFFERS) do
    if buffer.dirty then
      list[#list + 1] = buffer.filename or buffer._type or L('Untitled')
    end
  end
  if #list > 0 and gui.dialog('msgbox',
                              '--title', L('Quit without saving?'),
                              '--text', L('The following buffers are unsaved:'),
                              '--informative-text', table.concat(list, '\n'),
                              '--button1', 'gtk-cancel',
                              '--button2', L('Quit _without saving'),
                              '--no-newline') ~= '2' then
    return false
  end
  return true
end)

connect(events.ERROR, function(...) gui._print(L('[Error Buffer]'), ...) end)
