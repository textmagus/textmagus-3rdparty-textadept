-- Copyright 2007-2009 Mitchell Foral mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept

package.path = _HOME..'/core/?.lua;'..package.path
if not WIN32 then
  package.cpath = _HOME..'/core/?.so;'..package.cpath
else
  package.cpath = _HOME..'/core/?.dll;'..package.cpath
end

_THEME = 'light'
local user_dir = os.getenv(not WIN32 and 'HOME' or 'USERPROFILE')
if user_dir then
  local f = io.open(user_dir..'/.ta_theme', 'rb')
  if f then
    theme = f:read('*line'):match('[^\r\n]+')
    f:close()
    if theme and #theme > 0 then _THEME = theme end
  end
end

require 'iface'
require 'locale'
require 'events'
require 'file_io'
if not MAC then
  require 'lua_dialog'
end

rawset = nil -- do not allow modifications which could compromise stability

-- LuaDoc is in core/.textadept.lua.
function textadept.check_focused_buffer(buffer)
  if type(buffer) ~= 'table' or not buffer.doc_pointer then
    error(locale.ERR_BUFFER_EXPECTED, 2)
  elseif textadept.focused_doc_pointer ~= buffer.doc_pointer then
    error(locale.ERR_BUFFER_NOT_FOCUSED, 2)
  end
end

-- LuaDoc is in core/.textadept.lua.
function textadept._print(buffer_type, ...)
  local function safe_print(...)
    local message = table.concat({...}, '\t')
    local message_buffer, message_buffer_index
    local message_view, message_view_index
    for index, buffer in ipairs(textadept.buffers) do
      if buffer._type == buffer_type then
        message_buffer, message_buffer_index = buffer, index
        for jndex, view in ipairs(textadept.views) do
          if view.doc_pointer == message_buffer.doc_pointer then
            message_view, message_view_index = view, jndex
            break
          end
        end
        break
      end
    end
    if not message_view then
      local _, message_view = view:split(false) -- horizontal split
      if not message_buffer then
        message_buffer = textadept.new_buffer()
        message_buffer._type = buffer_type
      else
        message_view:goto_buffer(message_buffer_index, true)
      end
    else
      textadept.goto_view(message_view_index, true)
    end
    message_buffer:append_text(message..'\n')
    message_buffer:set_save_point()
  end
  pcall(safe_print, ...) -- prevent endless loops if this errors
end

-- LuaDoc is in core/.textadept.lua.
function textadept.print(...) textadept._print(locale.MESSAGE_BUFFER, ...) end

-- LuaDoc is in core/.textadept.lua.
function cocoa_dialog(kind, opts)
  local args = { kind }
  for k, v in pairs(opts) do
    args[#args + 1] = '--'..k
    if k == 'items' and kind:find('dropdown') then
      if not MAC then
        for item in v:gmatch('"(.-)"%s+') do args[#args + 1] = item end
      else
        args[#args + 1] = v
      end
    elseif type(v) == 'string' then
      args[#args + 1] = not MAC and v or '"'..v..'"'
    end
  end
  if not MAC then
    return lua_dialog.run(args)
  else
    local cocoa_dialog = '/CocoaDialog.app/Contents/MacOS/CocoaDialog '
    local p = io.popen(_HOME..cocoa_dialog..table.concat(args, ' '))
    local out = p:read('*all')
    p:close()
    return out
  end
end
