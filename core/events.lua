-- Copyright 2007-2010 Mitchell Foral mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- Textadept's core event structure and handlers.
module('textadept.events', package.seeall)

-- Markdown:
-- ## Overview
--
-- Textadept is very event-driven. Most of its functionality comes through event
-- handlers. Events occur when you create a new buffer, press a key, click on a
-- menu, etc. You can even make an event occur with Lua code. Instead of having
-- a single event handler however, each event can have a set of handlers. These
-- handlers are simply Lua functions that are called in the order they were
-- added to an event. This enables dynamically loaded modules to add their own
-- handlers to events.
--
-- Events themselves are nothing special. They do not have to be declared in
-- order to be used. They are simply strings containing an arbitrary event name.
-- When an event of this name occurs, either generated by Textadept or you, all
-- event handlers assigned to it are run.
--
-- Events can be given any number of arguments. These arguments will be passed
-- to the event's handler functions. If a handler returns either true or false
-- explicitly, all subsequent handlers are not called. This is useful if you
-- want to stop the propagation of an event like a keypress.
--
-- ## Textadept Events
--
-- The following is a list of all Scintilla events generated by Textadept in
-- `event_name(arguments)` format:
--
-- * **char\_added** (ch)<br />
--   Called when an ordinary text character is added to the buffer.
--       - ch: the ASCII representation of the character.
-- * **save\_point\_reached** ()<br />
--   Called when a save point is entered.
-- * **save\_point\_left** ()<br />
--   Called when a save point is left.
-- * **double\_click** (position, line)<br />
--   Called when the mouse button is double-clicked.
--       - position: the text position the click occured at.
--       - line: the line number the click occured at.
-- * **update\_ui** ()<br />
--   Called when the text or styling of the buffer has changed or the selection
--   range has changed.
-- * **margin\_click** (margin, modifiers, position)<br />
--   Called when the mouse is clicked inside a margin.
--       - margin: the margin number that was clicked.
--       - modifiers: the appropriate combination of `SCI_SHIFT`, `SCI_CTRL`,
--         and `SCI_ALT` to indicate the keys that were held down at the time of
--         the margin click.
--       - position: The position of the start of the line in the buffer that
--         corresponds to the margin click.
-- * **user\_list\_selection** (wParam, text)<br />
--   Called when the user has selected an item in a user list.
--       - wParam: the list_type parameter from
--         [`buffer:user_list_show()`][buffer_user_list_show].
--       - text: the text of the selection.
-- * **uri\_dropped** (text)<br />
--   Called when the user has dragged a URI such as a file name or web address
--   into Textadept.
--       - text: URI text.
-- * **call\_tip\_click** (position)<br />
--   Called when the user clicks on a calltip.
--       - position: 1 if the click is in an up arrow, 2 if in a down arrow, and
--         0 if elsewhere.
-- * **auto\_c\_selection** (lParam, text)<br />
--   Called when the user has selected an item in an autocompletion list.
--       - lParam: the start position of the word being completed.
--       - text: the text of the selection.
--
-- [buffer_user_list_show]: ../modules/buffer.html#buffer:user_list_show
--
-- The following is a list of all Textadept events generated in
-- `event_name(arguments)` format:
--
-- * **buffer\_new** ()<br />
--   Called when a new [buffer][buffer] is created.
-- * **buffer\_deleted** ()<br />
--   Called when a [buffer][buffer] has been deleted.
-- * **buffer\_before\_switch** ()<br />
--   Called right before another [buffer][buffer] is switched to.
-- * **buffer\_after\_switch** ()<br />
--   Called right after a [buffer][buffer] was switched to.
-- * **view\_new** ()<br />
--   Called when a new [view][view] is created.
-- * **view\_before\_switch** ()<br />
--   Called right before another [view][view] is switched to.
-- * **view\_after\_switch** ()<br />
--   Called right after [view][view] was switched to.
-- * **reset\_before()**<br />
--   Called before resetting the Lua state during a call to
--   [`textadept.reset()`][textadept_reset].
-- * **reset\_after()**<br />
--   Called after resetting the Lua state during a call to
--   [`textadept.reset()`][textadept_reset].
-- * **quit** ()<br />
--   Called when quitting Textadept.<br />
--   Note: Any quit handlers added must be inserted at index 1 because the
--   default quit handler in `core/events.lua` returns `true`, which ignores all
--   subsequent handlers.
-- * **keypress** (code, shift, control, alt)<br />
--   Called when a key is pressed.
--       - code: the key code (according to `<gdk/gdkkeysyms.h>`).
--       - shift: flag indicating whether or not the Shift key is pressed.
--       - control: flag indicating whether or not the Control key is pressed.
--       - alt: flag indicating whether or not the Alt/Apple key is pressed.
--   <br />
--   Note: The Alt-Option key in Mac OSX is not available.
-- * **menu\_clicked** (menu\_id)<br />
--   Called when a menu item is selected.
--       - menu\_id: the numeric ID of the menu item set in
--         [`textadept.gtkmenu()`][textadept_gtkmenu].
-- * **find** (text, next)<br />
--   Called when attempting to finding text via the Find dialog box.
--       - text: the text to search for.
--       - next: flat indicating whether or not the search direction is forward.
-- * **replace** (text)<br />
--   Called when the found text is selected and asked to be replaced.
--       - text: the text to replace the selected text with.
-- * **replace\_all** (find\_text, repl\_text)<br />
--   Called when all occurances of found text are to be replaced.
--       - find\_text: the text to search for.
--       - repl\_text: the text to replace found text with.
-- * **command\_entry\_keypress** (code)<br />
--   Called when a key is pressed in the Command Entry.
--       - code: the key code (according to `<gdk/gdkkeysyms.h>`).
--
-- [buffer]: ../modules/buffer.html
-- [view]: ../modules/view.html
-- [textadept_reset]: ../modules/textadept.html#reset
-- [textadept_gtkmenu]: ../modules/textadept.html#gtkmenu
--
-- ## Example
--
-- The following Lua code generates and handles a custom `my_event` event:
--
--     function my_event_handler(message)
--       textadept.print(message)
--     end
--
--     textadept.events.add_handler('my_event', my_event_handler)
--     textadept.events.handle('my_event', 'my message')

local events = textadept.events

---
-- Adds a handler function to an event.
-- @param event The string event name. It is arbitrary and need not be defined
--   anywhere.
-- @param f The Lua function to add.
-- @param index Optional index to insert the handler into.
function add_handler(event, f, index)
  local plural = event..'s'
  if not events[plural] then events[plural] = {} end
  local handlers = events[plural]
  if index then
    table.insert(handlers, index, f)
  else
    handlers[#handlers + 1] = f
  end
end

---
-- Calls all handlers for the given event in sequence (effectively "generating"
-- the event).
-- If true or false is explicitly returned by any handler, the event is not
-- propagated any further; iteration ceases.
-- @param event The string event name.
-- @param ... Arguments passed to the handler.
-- @return true or false if any handler explicitly returned such; nil otherwise.
function handle(event, ...)
  local plural = event..'s'
  local handlers = events[plural]
  if not handlers then return end
  for _, f in ipairs(handlers) do
    local result = f(unpack{...})
    if result == true or result == false then return result end
  end
end

--- Map of Scintilla notifications to their handlers.
local c = textadept.constants
local scnnotifications = {
  [c.SCN_CHARADDED] = { 'char_added', 'ch' },
  [c.SCN_SAVEPOINTREACHED] = { 'save_point_reached' },
  [c.SCN_SAVEPOINTLEFT] = { 'save_point_left' },
  [c.SCN_DOUBLECLICK] = { 'double_click', 'position', 'line' },
  [c.SCN_UPDATEUI] = { 'update_ui' },
  [c.SCN_MARGINCLICK] = { 'margin_click', 'margin', 'modifiers', 'position' },
  [c.SCN_USERLISTSELECTION] = { 'user_list_selection', 'wParam', 'text' },
  [c.SCN_URIDROPPED] = { 'uri_dropped', 'text' },
  [c.SCN_CALLTIPCLICK] = { 'call_tip_click', 'position' },
  [c.SCN_AUTOCSELECTION] = { 'auto_c_selection', 'lParam', 'text' }
}

---
-- Handles Scintilla notifications.
-- @param n The Scintilla notification structure as a Lua table.
-- @return true or false if any handler explicitly returned such; nil otherwise.
function notification(n)
  local f = scnnotifications[n.code]
  if f then
    local args = { unpack(f, 2) }
    for k, v in ipairs(args) do args[k] = n[v] end
    return handle(f[1], unpack(args))
  end
end

-- Default handlers to follow.

add_handler('view_new',
  function() -- sets default properties for a Scintilla window
    local buffer = buffer
    local c = textadept.constants

    -- lexer
    buffer.style_bits = 8
    buffer:set_lexer_language('container')

    -- allow redefinitions of these Scintilla key commands
    local ctrl_keys = { 'Z', 'Y', 'X', 'C', 'V', 'A', 'D' }
    local ctrl_shift_keys = { '[', ']', '/', '\\', 'L', 'T', 'U' }
    for _, key in ipairs(ctrl_keys) do
      buffer:clear_cmd_key(string.byte(key), c.SCMOD_CTRL)
    end
    for _, key in ipairs(ctrl_shift_keys) do
      buffer:clear_cmd_key(string.byte(key), c.SCMOD_CTRL + c.SCMOD_SHIFT)
    end

    if _THEME and #_THEME > 0 then
      local ret, errmsg = pcall(dofile, _THEME..'/view.lua')
      if ret then return end
      io.stderr:write(errmsg)
    end
  end)

add_handler('buffer_new',
  function() -- sets default properties for a Scintilla document
    local function run()
      local buffer = buffer

      -- properties
      buffer.property['textadept.home'] = _HOME
      buffer.property['lexer.lua.home'] = _LEXERPATH
      buffer.property['lexer.lua.script'] = _HOME..'/lexers/lexer.lua'
      if _THEME and #_THEME > 0 then
        buffer.property['lexer.lua.color.theme'] = _THEME..'/lexer.lua'
      end

      -- lexer
      buffer.style_bits = 8
      buffer:set_lexer_language('container')

      -- buffer
      buffer.code_page = textadept.constants.SC_CP_UTF8

      if _THEME and #_THEME > 0 then
        local ret, errmsg = pcall(dofile, _THEME..'/buffer.lua')
        if ret then return end
        io.stderr:write(errmsg)
      end
    end
    -- normally when an error occurs, a new buffer is created with the error
    -- message, but if an error occurs here, this event would be called again
    -- and again, erroring each time resulting in an infinite loop; print error
    -- to stderr instead
    local ret, errmsg = pcall(run)
    if not ret then io.stderr:write(errmsg) end
  end)

-- Sets the title of the Textadept window to the buffer's filename.
-- @param buffer The currently focused buffer.
local function set_title(buffer)
  local buffer = buffer
  local filename = buffer.filename or buffer._type or locale.UNTITLED
  local dirty = buffer.dirty and '*' or '-'
  textadept.title =
    string.format('%s %s Textadept (%s)', filename:match('[^/\\]+$'), dirty,
                  filename)
end

add_handler('save_point_reached',
  function() -- changes Textadept title to show 'clean' buffer
    buffer.dirty = false
    set_title(buffer)
  end)

add_handler('save_point_left',
  function() -- changes Textadept title to show 'dirty' buffer
    buffer.dirty = true
    set_title(buffer)
  end)

add_handler('uri_dropped',
  function(utf8_uris)
    local lfs = require 'lfs'
    for utf8_uri in utf8_uris:gmatch('[^\r\n\f]+') do
      if utf8_uri:find('^file://') then
        utf8_uri = utf8_uri:match('^file://([^\r\n\f]+)')
        utf8_uri = utf8_uri:gsub('%%(%x%x)',
          function(hex) return string.char(tonumber(hex, 16)) end)
        if WIN32 then utf8_uri = utf8_uri:sub(2, -1) end -- ignore leading '/'
        local uri = textadept.iconv(utf8_uri, _CHARSET, 'UTF-8')
        if lfs.attributes(uri).mode ~= 'directory' then
          textadept.io.open(utf8_uri)
        end
      end
    end
  end)

local EOLs = {
  locale.STATUS_CRLF,
  locale.STATUS_CR,
  locale.STATUS_LF
}
add_handler('update_ui',
  function() -- sets docstatusbar text
    local buffer = buffer
    local pos = buffer.current_pos
    local line, max = buffer:line_from_position(pos) + 1, buffer.line_count
    local col = buffer.column[pos] + 1
    local lexer = buffer:get_lexer_language()
    local eol = EOLs[buffer.eol_mode + 1]
    local tabs = (buffer.use_tabs and locale.STATUS_TABS or
      locale.STATUS_SPACES)..buffer.indent
    local enc = buffer.encoding or ''
    textadept.docstatusbar_text =
      locale.DOCSTATUSBAR_TEXT:format(line, max, col, lexer, eol, tabs, enc)
  end)

add_handler('margin_click',
  function(margin, modifiers, position) -- toggles folding
    local line = buffer:line_from_position(position)
    buffer:toggle_fold(line)
  end)

add_handler('buffer_new',
  function() -- set additional buffer functions
    local buffer = buffer
    buffer.reload = textadept.io.reload
    buffer.set_encoding = textadept.io.set_encoding
    buffer.save = textadept.io.save
    buffer.save_as = textadept.io.save_as
    buffer.close = textadept.io.close
    buffer.encoding = 'UTF-8'
    set_title(buffer)
  end)

add_handler('buffer_before_switch',
  function() -- save buffer properties
    local buffer = buffer
    -- Save view state.
    buffer._anchor = buffer.anchor
    buffer._current_pos = buffer.current_pos
    buffer._first_visible_line = buffer.first_visible_line
    -- Save fold state.
    buffer._folds = {}
    local folds = buffer._folds
    local level, expanded = buffer.fold_level, buffer.fold_expanded
    local header_flag = textadept.constants.SC_FOLDLEVELHEADERFLAG
    local test = 2 * header_flag
    for i = 0, buffer.line_count do
      if level[i] % test >= header_flag and not expanded[i] then
        folds[#folds + 1] = i
      end
    end
  end)

add_handler('buffer_after_switch',
  function() -- restore buffer properties
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

add_handler('buffer_after_switch',
  function() -- updates titlebar and statusbar
    set_title(buffer)
    handle('update_ui')
  end)

add_handler('view_after_switch',
  function() -- updates titlebar and statusbar
    set_title(buffer)
    handle('update_ui')
  end)

add_handler('quit',
  function() -- prompts for confirmation if any buffers are dirty
    local any = false
    local list = {}
    for _, buffer in ipairs(textadept.buffers) do
      if buffer.dirty then
        list[#list + 1] = buffer.filename or buffer._type or locale.UNTITLED
        any = true
      end
    end
    if any and
       textadept.dialog('msgbox',
                        '--title', locale.EVENTS_QUIT_TITLE,
                        '--text', locale.EVENTS_QUIT_TEXT,
                        '--informative-text',
                          string.format('%s', table.concat(list, '\n')),
                        '--button1', 'gtk-cancel',
                        '--button2', locale.EVENTS_QUIT_BUTTON2,
                        '--no-newline') ~= '2' then
      return false
    end
    return true
  end)

if MAC then
  add_handler('appleevent_odoc',
    function(uri) return handle('uri_dropped', 'file://'..uri) end)
end

add_handler('error',
  function(...) textadept._print(locale.ERROR_BUFFER, ...) end)
