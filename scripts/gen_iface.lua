#!/usr/bin/lua
-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

-- This script generates the _SCINTILLA table from SciTE's Lua Interface tables.

local f = io.open('../../scite-latest/scite/src/IFaceTable.cxx')
local iface = f:read('*all')
f:close()

local string_format = string.format
local constants, fielddoc, functions, properties = {}, {}, {}, {}
local types = {
  void = 0, int = 1, length = 2, position = 3, colour = 4, bool = 5,
  keymod = 6, string = 7, stringresult = 8, cells = 9, textrange = 10,
  findtext = 11, formatrange = 12
}
local s = '_G._SCINTILLA.constants'

f = io.open('../core/iface.lua', 'w')

-- Write header.
f:write [[
-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Scintilla constants, functions, and properties.
-- Do not modify anything in this module. Doing so will result in instability.
module('_SCINTILLA')

]]

-- Constants ({"constant", value}).
for item in iface:match('Constants%[%] = (%b{})'):sub(2, -2):gmatch('%b{}') do
  local name, value = item:match('^{"(.-)",(.-)}')
  if not name:find('^IDM_') and not name:find('^SCE_') and
     not name:find('^SCLEX_') then
    if name == 'SC_MASK_FOLDERS' then value = '-33554432' end
    constants[#constants + 1] = string_format('%s=%s', name, value)
    fielddoc[#fielddoc + 1] = string_format('-- * `%s.%s`: %d', s, name, value)
  end
end

-- Events added to constants.
local events = {
  SCN_STYLENEEDED = 2000,
  SCN_CHARADDED = 2001,
  SCN_SAVEPOINTREACHED = 2002,
  SCN_SAVEPOINTLEFT = 2003,
  SCN_MODIFYATTEMPTRO = 2004,
  SCN_KEY = 2005,
  SCN_DOUBLECLICK =2006,
  SCN_UPDATEUI = 2007,
  SCN_MODIFIED = 2008,
  SCN_MACRORECORD = 2009,
  SCN_MARGINCLICK = 2010,
  SCN_NEEDSHOWN = 2011,
  SCN_PAINTED = 2013,
  SCN_USERLISTSELECTION = 2014,
  SCN_URIDROPPED = 2015,
  SCN_DWELLSTART = 2016,
  SCN_DWELLEND = 2017,
  SCN_ZOOM = 2018,
  SCN_HOTSPOTCLICK = 2019,
  SCN_HOTSPOTDOUBLECLICK = 2020,
  SCN_CALLTIPCLICK = 2021,
  SCN_AUTOCSELECTION = 2022,
  SCN_INDICATORCLICK = 2023,
  SCN_INDICATORRELEASE = 2024,
  SCN_AUTOCCANCELLED = 2026,
  SCN_AUTOCCHARDELETED = 2027,
  SCN_HOTSPOTRELEASECLICK = 2028
}
for event, value in pairs(events) do
  constants[#constants + 1] = string_format('%s=%d', event, value)
  fielddoc[#fielddoc + 1] = string_format('-- * `%s.%s`: %d', s, event, value)
end
-- Lexers added to constants.
local lexers = {
  SCLEX_CONTAINER = 0,
  SCLEX_NULL = 1,
  SCLEX_LPEG = 999,
  SCLEX_AUTOMATIC = 1000
}
for lexer, value in pairs(lexers) do
  constants[#constants + 1] = string_format('%s=%d', lexer, value)
  fielddoc[#fielddoc + 1] = string_format('-- * `%s.%s`: %d', s, lexer, value)
end

-- Write constants.
f:write [[
---
-- Scintilla constants.
-- @class table
-- @name constants
constants = {]]
f:write(table.concat(constants, ','))
f:write('}\n\n')

-- Functions ({"function", msg_id, iface_*, {iface_*, iface_*}}).
for item in iface:match('Functions%[%] = (%b{})'):sub(2, -2):gmatch('%b{}') do
  local name, msg_id, rt_type, p1_type, p2_type =
    item:match('^{"(.-)"%D+(%d+)%A+iface_(%a+)%A+iface_(%a+)%A+iface_(%a+)')
  name = name:gsub('([a-z])([A-Z])', '%1_%2')
  name = name:gsub('([A-Z])([A-Z][a-z])', '%1_%2')
  name = name:lower()
  local line = string_format('%s={%d,%d,%d,%d}', name, msg_id, types[rt_type],
                             types[p1_type], types[p2_type])
  functions[#functions + 1] = line
end

-- Write functions.
f:write [[
---
-- Scintilla functions.
-- @class table
-- @name functions
functions = {]]
f:write(table.concat(functions, ','))
f:write('}\n\n')

-- Properties ({"property", get_id, set_id, rt_type, p1_type}).
for item in iface:match('Properties%[%] = (%b{})'):sub(2, -2):gmatch('%b{}') do
  local name, get_id, set_id, rt_type, p1_type =
    item:match('^{"(.-)"%D+(%d+)%D+(%d+)%A+iface_(%a+)%A+iface_(%a+)')
  name = name:gsub('([a-z])([A-Z])', '%1_%2')
  name = name:gsub('([A-Z])([A-Z][a-z])', '%1_%2')
  name = name:lower()
  properties[#properties + 1] = string_format('%s={%d,%d,%d,%d}', name, get_id,
                                              set_id, types[rt_type],
                                              types[p1_type])
end

-- Write properties.
f:write [[
---
-- Scintilla properties.
-- @class table
-- @name properties
properties = {]]
f:write(table.concat(properties, ','))
f:write('}\n\n')

-- Write footer.
f:write [[
local marker_number, indic_number, list_type = -1, 7, 0

---
-- Returns a unique marker number.
-- Use this function for custom markers in order to prevent clashes with
-- identifiers of other custom markers.
-- @usage local marknum = _SCINTILLA.next_marker_number()
-- @see buffer.marker_define
function next_marker_number()
  marker_number = marker_number + 1
  return marker_number
end

---
-- Returns a unique indicator number.
-- Use this function for custom indicators in order to prevent clashes with
-- identifiers of other custom indicators.
-- @usage local indic_num = _SCINTILLA.next_indic_number()
function next_indic_number()
  indic_number = indic_number + 1
  return indic_number
end

---
-- Returns a unique user list type.
-- Use this function for custom user lists in order to prevent clashes with
-- type identifiers of other custom user lists.
-- @usage local list_type = _SCINTILLA.next_user_list_type()
-- @see buffer.user_list_show
function next_user_list_type()
  list_type = list_type + 1
  return list_type
end
]]

f:close()

f = io.open('../core/._SCINTILLA.luadoc', 'w')
f:write [[
-- Copyright 2007-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making Adeptsense for built-in constants in the
-- global _SCINTILLA.constants table.

]]
f:write(table.concat(fielddoc, '\n'))
f:write('\n')
f:close()
