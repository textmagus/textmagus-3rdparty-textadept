-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = gui.find

--[[ This comment is for LuaDoc.
---
-- Textadept's Find & Replace pane.
-- @field find_entry_text (string)
--   The text in the find entry.
-- @field replace_entry_text (string)
--   The text in the replace entry.
-- @field match_case (bool)
--   Searches are case-sensitive.
--   The default value is `false`.
-- @field whole_word (bool)
--   Match only whole-words in searches.
--   The default value is `false`.
-- @field lua (bool)
--   Interpret search text as a Lua pattern.
--   The default value is `false`.
-- @field in_files (bool)
--   Search for the text in a list of files.
--   The default value is `false`.
-- @field find_label_text (string, Write-only)
--   The text of the "Find" label.
--   This is primarily used for localization.
-- @field replace_label_text (string, Write-only)
--   The text of the "Replace" label.
--   This is primarily used for localization.
-- @field find_next_button_text (string, Write-only)
--   The text of the "Find Next" button.
--   This is primarily used for localization.
-- @field find_prev_button_text (string, Write-only)
--   The text of the "Find Prev" button.
--   This is primarily used for localization.
-- @field replace_button_text (string, Write-only)
--   The text of the "Replace" button.
--   This is primarily used for localization.
-- @field replace_all_button_text (string, Write-only)
--   The text of the "Replace All" button.
--   This is primarily used for localization.
-- @field match_case_label_text (string, Write-only)
--   The text of the "Match case" label.
--   This is primarily used for localization.
-- @field whole_word_label_text (string, Write-only)
--   The text of the "Whole word" label.
--   This is primarily used for localization.
-- @field lua_pattern_label_text (string, Write-only)
--   The text of the "Lua pattern" label.
--   This is primarily used for localization.
-- @field in_files_label_text (string, Write-only)
--   The text of the "In files" label.
--   This is primarily used for localization.
-- @field _G.events.FIND_WRAPPED (string)
--   Called when a search for text wraps, either from bottom to top when
--   searching for a next occurrence, or from top to bottom when searching for a
--   previous occurrence.
--   This is useful for implementing a more visual or audible notice when a
--   search wraps in addition to the statusbar message.
module('gui.find')]]

local _L = _L
M.find_label_text = not CURSES and _L['_Find:'] or _L['Find:']
M.replace_label_text = not CURSES and _L['R_eplace:'] or _L['Replace:']
M.find_next_button_text = not CURSES and _L['Find _Next'] or _L['[Next]']
M.find_prev_button_text = not CURSES and _L['Find _Prev'] or _L['[Prev]']
M.replace_button_text = not CURSES and _L['_Replace'] or _L['[Replace]']
M.replace_all_button_text = not CURSES and _L['Replace _All'] or _L['[All]']
M.match_case_label_text = not CURSES and _L['_Match case'] or _L['Case(F1)']
M.whole_word_label_text = not CURSES and _L['_Whole word'] or _L['Word(F2)']
M.lua_pattern_label_text = not CURSES and _L['_Lua pattern'] or
                           _L['Pattern(F3)']
M.in_files_label_text = not CURSES and _L['_In files'] or _L['Files(F4)']

-- Events.
local events, events_connect = events, events.connect
events.FIND_WRAPPED = 'find_wrapped'

local MARK_FIND = _SCINTILLA.next_marker_number()
local MARK_FIND_COLOR = 0x4D9999
local preferred_view

---
-- Table of Lua patterns matching files and folders to exclude when finding in
-- files.
-- Each filter string is a pattern that matches filenames to exclude, with
-- patterns matching folders to exclude listed in a `folders` sub-table.
-- Patterns starting with '!' exclude files and folders that do not match the
-- pattern that follows. Use a table of raw file extensions assigned to an
-- `extensions` key for fast filtering by extension. All strings must be encoded
-- in `_G._CHARSET`, not UTF-8.
-- The default value is `lfs.FILTER`, a filter for common binary file extensions
-- and version control folders.
-- @see find_in_files
-- @class table
-- @name FILTER
M.FILTER = lfs.FILTER

-- Text escape sequences with their associated characters.
-- @class table
-- @name escapes
local escapes = {
  ['\\a'] = '\a', ['\\b'] = '\b', ['\\f'] = '\f', ['\\n'] = '\n',
  ['\\r'] = '\r', ['\\t'] = '\t', ['\\v'] = '\v', ['\\\\'] = '\\'
}

---
-- Searches the *utf8_dir* or user-specified directory for files that match
-- search text and options and prints the results to a buffer.
-- Use the `find_text`, `match_case`, `whole_word`, and `lua` fields to set the
-- search text and option flags, respectively. Use `FILTER` to set the search
-- filter.
-- @param utf8_dir Optional UTF-8-encoded directory path to search. If `nil`,
--   the user is prompted for one.
-- @see FILTER
-- @name find_in_files
function M.find_in_files(utf8_dir)
  if not utf8_dir then
    utf8_dir = gui.dialog('fileselect',
                          '--title', _L['Find in Files'],
                          '--select-only-directories',
                          '--with-directory',
                          (buffer.filename or ''):match('^.+[/\\]') or '',
                          '--no-newline')
  end
  if utf8_dir == '' then return end

  local text = M.find_entry_text
  if not M.lua then text = text:gsub('([().*+?^$%%[%]-])', '%%%1') end
  if not M.match_case then text = text:lower() end
  if M.whole_word then text = '%f[%w_]'..text..'%f[^%w_]' end
  local matches = {_L['Find:']..' '..text}
  lfs.dir_foreach(utf8_dir, function(file)
    local match_case = M.match_case
    local line_num = 1
    for line in io.lines(file) do
      if (match_case and line or line:lower()):find(text) then
        file = file:iconv('UTF-8', _CHARSET)
        matches[#matches + 1] = ('%s:%s:%s'):format(file, line_num, line)
      end
      line_num = line_num + 1
    end
  end, M.FILTER, true)
  if #matches == 1 then matches[2] = _L['No results found'] end
  matches[#matches + 1] = ''
  if buffer._type ~= _L['[Files Found Buffer]'] then preferred_view = view end
  gui._print(_L['[Files Found Buffer]'], table.concat(matches, '\n'))
end

local c = _SCINTILLA.constants

-- Finds and selects text in the current buffer.
-- @param text The text to find.
-- @param next Flag indicating whether or not the search direction is forward.
-- @param flags Search flags. This is a number mask of 4 flags: match case (2),
--   whole word (4), Lua pattern (8), and in files (16) joined with binary OR.
--   If `nil`, this is determined based on the checkboxes in the find box.
-- @param nowrap Flag indicating whether or not the search will not wrap.
-- @param wrapped Utility flag indicating whether or not the search has wrapped
--   for displaying useful statusbar information. This flag is used and set
--   internally, and should not be set otherwise.
-- @return position of the found text or `-1`
local function find_(text, next, flags, nowrap, wrapped)
  if text == '' then return end
  local buffer = buffer
  local first_visible_line = buffer.first_visible_line -- for 'no results found'

  local increment
  if buffer.current_pos == buffer.anchor then
    increment = 0
  elseif not wrapped then
    increment = next and 1 or -1
  end

  if not flags then
    flags = 0
    if M.match_case then flags = flags + c.SCFIND_MATCHCASE end
    if M.whole_word then flags = flags + c.SCFIND_WHOLEWORD end
    if M.lua then flags = flags + 8 end
    if M.in_files then flags = flags + 16 end
  end

  local result
  M.captures = nil

  if flags < 8 then
    buffer:goto_pos(buffer[next and 'current_pos' or 'anchor'] + increment)
    buffer:search_anchor()
    result = buffer['search_'..(next and 'next' or 'prev')](buffer, flags, text)
    buffer:scroll_range(buffer.anchor, buffer.current_pos)
  elseif flags < 16 then -- lua pattern search (forward search only)
    text = text:gsub('\\[abfnrtv\\]', escapes)
    local buffer_text = buffer:get_text(buffer.length)
    local results = {buffer_text:find(text, buffer.anchor + increment + 1)}
    if #results > 0 then
      M.captures = {table.unpack(results, 3)}
      buffer:set_sel(results[2], results[1] - 1)
    end
    result = results[1] or -1
  else -- find in files
    M.find_in_files()
    return
  end

  if result == -1 and not nowrap and not wrapped then -- wrap the search
    local anchor, pos = buffer.anchor, buffer.current_pos
    buffer:goto_pos((next or flags >= 8) and 0 or buffer.length)
    gui.statusbar_text = _L['Search wrapped']
    events.emit(events.FIND_WRAPPED)
    result = find_(text, next, flags, true, true)
    if result == -1 then
      gui.statusbar_text = _L['No results found']
      buffer:line_scroll(0, first_visible_line)
      buffer:goto_pos(anchor)
    end
    return result
  elseif result ~= -1 and not wrapped then
    gui.statusbar_text = ''
  end

  return result
end
events_connect(events.FIND, find_)

-- Finds and selects text incrementally in the current buffer from a starting
-- position.
-- Flags other than `SCFIND_MATCHCASE` are ignored.
-- @param text The text to find.
-- @param next Flag indicating whether or not the search direction is forward.
local function find_incremental(text, next)
  buffer:goto_pos(M.incremental_start or 0)
  find_(text, next, M.match_case and c.SCFIND_MATCHCASE or 0)
end

---
-- Begins an incremental search using the command entry if *text* is `nil`;
-- otherwise continues an incremental search by searching for the next instance
-- of string *text*.
-- Only the `match_case` find option is recognized. Normal command entry
-- functionality is unavailable until the search is finished by pressing `Esc`
-- (`⎋` on Mac OSX | `Esc` in curses).
-- @param text The text to incrementally search for, or `nil` to begin an
--   incremental search.
-- @name find_incremental
function M.find_incremental(text)
  if text then find_incremental(text, true) return end
  M.incremental_start = buffer.current_pos
  gui.command_entry.entry_text = ''
  gui.command_entry.enter_mode('find_incremental')
end

---
-- Continues an incremental search by searching for the next match starting from
-- the current position.
-- @see find_incremental
-- @name find_incremental_next
function M.find_incremental_next()
  M.incremental_start = buffer.current_pos + 1
  find_incremental(gui.command_entry.entry_text, true)
end

---
-- Continues an incremental search by searching for the previous match starting
-- from the current position.
-- @see find_incremental
-- @name find_incremental_prev
function M.find_incremental_prev()
  M.incremental_start = buffer.current_pos - 1
  find_incremental(gui.command_entry.entry_text, false)
end

-- Optimize for speed.
local load, pcall = load, pcall

-- Runs the given code.
-- This function is passed to `string.gsub()` in the `replace()` function.
-- @param code The code to run.
local function run(code)
  local ok, val = pcall(load('return '..code))
  if not ok then
    gui.dialog('ok-msgbox',
               '--title', _L['Error'],
               '--text', _L['An error occured:'],
               '--informative-text', val:gsub('"', '\\"'),
               '--button1', _L['_OK'],
               '--button2', _L['_Cancel'],
               '--no-cancel')
    error()
  end
  return val
end

-- Replaces found text.
-- `find_()` is called first, to select any found text. The selected text is
-- then replaced by the specified replacement text.
-- This function ignores "Find in Files".
-- @param rtext The text to replace found text with. It can contain both Lua
--   capture items (`%n` where 1 <= `n` <= 9) for Lua pattern searches and `%()`
--   sequences for embedding Lua code for any search.
-- @see find
local function replace(rtext)
  if buffer:get_sel_text() == '' then return end
  if M.in_files then M.in_files = false end
  local buffer = buffer
  buffer:target_from_selection()
  rtext = rtext:gsub('%%%%', '\\037') -- escape '%%'
  local captures = M.captures
  if captures then
    for i = 1, #captures do
      rtext = rtext:gsub('%%'..i, (captures[i]:gsub('%%', '%%%%')))
    end
  end
  local ok, rtext = pcall(rtext.gsub, rtext, '%%(%b())', run)
  if ok then
    rtext = rtext:gsub('\\037', '%%') -- unescape '%'
    buffer:replace_target(rtext:gsub('\\[abfnrtv\\]', escapes))
    buffer:goto_pos(buffer.target_end) -- 'find' text after this replacement
  else
    -- Since find is called after replace returns, have it 'find' the current
    -- text again, rather than the next occurance so the user can fix the error.
    buffer:goto_pos(buffer.current_pos)
  end
end
events_connect(events.REPLACE, replace)

-- Replaces all found text.
-- If any text is selected, all found text in that selection is replaced.
-- This function ignores "Find in Files".
-- @param ftext The text to find.
-- @param rtext The text to replace found text with.
-- @see find
local function replace_all(ftext, rtext)
  if ftext == '' then return end
  if M.in_files then M.in_files = false end
  local buffer = buffer
  buffer:begin_undo_action()
  local count = 0
  if buffer:get_sel_text() == '' then
    buffer:goto_pos(0)
    while(find_(ftext, true, nil, true) ~= -1) do
      replace(rtext)
      count = count + 1
    end
  else
    local anchor, current_pos = buffer.selection_start, buffer.selection_end
    local s, e = anchor, current_pos
    buffer:insert_text(e, '\n')
    local end_marker = buffer:marker_add(buffer:line_from_position(e + 1),
                                         MARK_FIND)
    buffer:goto_pos(s)
    local pos = find_(ftext, true, nil, true)
    while pos ~= -1 and
          pos < buffer:position_from_line(
                       buffer:marker_line_from_handle(end_marker)) do
      replace(rtext)
      count = count + 1
      pos = find_(ftext, true, nil, true)
    end
    e = buffer:position_from_line(buffer:marker_line_from_handle(end_marker))
    buffer:goto_pos(e)
    buffer:delete_back() -- delete '\n' added
    if s == current_pos then anchor = e - 1 else current_pos = e - 1 end
    buffer:set_sel(anchor, current_pos)
    buffer:marker_delete_handle(end_marker)
  end
  gui.statusbar_text = ("%d %s"):format(count, _L['replacement(s) made'])
  buffer:end_undo_action()
end
events_connect(events.REPLACE_ALL, replace_all)

-- When the user double-clicks a found file, go to the line in the file the text
-- was found at.
-- @param pos The position of the caret.
-- @param line_num The line double-clicked.
local function goto_file(pos, line_num)
  if buffer._type == _L['[Files Found Buffer]'] then
    line = buffer:get_line(line_num)
    local file, file_line_num = line:match('^(.+):(%d+):.+$')
    if file and file_line_num then
      buffer:marker_delete_all(MARK_FIND)
      buffer.marker_back[MARK_FIND] = MARK_FIND_COLOR
      buffer:marker_add(line_num, MARK_FIND)
      buffer:goto_pos(buffer.current_pos)
      gui.goto_file(file, true, preferred_view)
      _M.textadept.editing.goto_line(file_line_num)
    end
  end
end
events_connect(events.DOUBLE_CLICK, goto_file)

---
-- If *next* is `true`, goes to the next file found, relative to the file on the
-- current line in the results list. Otherwise goes to the previous file found.
-- @param next Optional flag indicating whether or not to go to the next file.
--   The default value is `false`.
-- @name goto_file_in_list
function M.goto_file_in_list(next)
  local orig_view = _VIEWS[view]
  for _, buffer in ipairs(_BUFFERS) do
    if buffer._type == _L['[Files Found Buffer]'] then
      for j, view in ipairs(_VIEWS) do
        if view.buffer == buffer then
          gui.goto_view(j)
          local orig_line = buffer:line_from_position(buffer.current_pos)
          local line = orig_line
          while true do
            line = line + (next and 1 or -1)
            if line > buffer.line_count - 1 then line = 0 end
            if line < 0 then line = buffer.line_count - 1 end
            -- Prevent infinite loops.
            if line == orig_line then gui.goto_view(orig_view) return end
            if buffer:get_line(line):match('^(.+):(%d+):.+$') then
              buffer:goto_line(line)
              goto_file(buffer.current_pos, line)
              return
            end
          end
        end
      end
    end
  end
end

if buffer then buffer.marker_back[MARK_FIND] = MARK_FIND_COLOR end
events_connect(events.VIEW_NEW, function()
  buffer.marker_back[MARK_FIND] = MARK_FIND_COLOR
end)

--[[ The functions below are Lua C functions.

---
-- Displays and focuses the Find & Replace pane.
-- @class function
-- @name focus
local focus

---
-- Mimics pressing the "Find Next" button.
-- @class function
-- @name find_next
local find_next

---
-- Mimics pressing the "Find Prev" button.
-- @class function
-- @name find_prev
local find_prev

---
-- Mimics pressing the "Replace" button.
-- @class function
-- @name replace
local replace

---
-- Mimics pressing the "Replace All" button.
-- @class function
-- @name replace_all
local replace_all
]]
