-- Copyright 2007-2013 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Modified by Jay Gould.

--[[ This comment is for LuaDoc.
---
-- Textadept's Command Entry.
-- @field entry_text (string)
--   The text in the entry.
module('gui.command_entry')]]

-- Environment for abbreviated commands.
-- @class table
-- @name env
local env = setmetatable({}, {
  __index = function(t, k)
    local f = buffer[k]
    if f and type(f) == 'function' then
      f = function(...) buffer[k](buffer, ...) end
    elseif f == nil then
      f = view[k] or gui[k] or _G[k]
    end
    return f
  end,
  __newindex = function(t, k, v)
    for _, t2 in ipairs{buffer, view, gui} do
      if t2[k] ~= nil then t2[k] = v return end
    end
    rawset(t, k, v)
  end,
})

local events = events

-- Execute a Lua command.
events.connect(events.COMMAND_ENTRY_COMMAND, function(command)
  local f, err = load(command, nil, 'bt', env)
  if err then error(err) end
  if not NCURSES then gui.command_entry.focus() end -- toggle focus to hide
  f()
  events.emit(events.UPDATE_UI)
end)

events.connect(events.COMMAND_ENTRY_KEYPRESS, function(code)
  if keys.KEYSYMS[code] == 'esc' then
    gui.command_entry.focus() -- toggle focus to hide
  elseif keys.KEYSYMS[code] == '\t' then
    local substring = gui.command_entry.entry_text:match('[%w_.:]+$') or ''
    local path, o, prefix = substring:match('^([%w_.:]-)([.:]?)([%w_]*)$')
    local f, err = load('return ('..path..')', nil, 'bt', env)
    local ok, tbl = pcall(f)
    local cmpls = {}
    prefix = '^'..prefix
    if not ok then -- shorthand notation
      for _, t in ipairs{buffer, view, gui, _G} do
        for k in pairs(t) do
          if type(k) == 'string' and k:find(prefix) then
            cmpls[#cmpls + 1] = k
          end
        end
      end
      for f in pairs(_SCINTILLA.functions) do
        if f:find(prefix) then cmpls[#cmpls + 1] = f end
      end
      for p in pairs(_SCINTILLA.properties) do
        if p:find(prefix) then cmpls[#cmpls + 1] = p end
      end
    else
      if type(tbl) ~= 'table' then return end
      for k in pairs(tbl) do
        if type(k) == 'string' and k:find(prefix) then cmpls[#cmpls + 1] = k end
      end
      if path == 'buffer' then
        if o == ':' then
          for f in pairs(_SCINTILLA.functions) do
            if f:find(prefix) then cmpls[#cmpls + 1] = f end
          end
        else
          for p in pairs(_SCINTILLA.properties) do
            if p:find(prefix) then cmpls[#cmpls + 1] = p end
          end
        end
      end
    end
    table.sort(cmpls)
    gui.command_entry.show_completions(cmpls)
    return true
  end
end)

-- Executes Lua code on startup.
local function execute(command)
  local f, err = load(command, nil, 'bt', env)
  if err then error(err) end
  f()
end
args.register('-e', '--execute', 1, execute, 'Execute Lua code')

--[[ The function below is a Lua C function.

---
-- Focuses the command entry.
-- @class function
-- @name focus
local focus

---
-- Shows the completion list *completions* for the current word prefix.
-- Word prefix characters are alphanumerics and underscores. On selection, the
-- word prefix is replaced with the completion.
-- @param completions The table of completions to show. Non-string values are
--   ignored.
-- @class function
-- @name show_completions
local show_completions
]]
