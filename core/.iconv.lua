-- Copyright 2007-2010 Mitchell Foral mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for built-in functions in the
-- string table.

--- Extends Lua's string package to provide character set conversions.
module('string')

---
-- Converts a string from one character set to another using iconv().
-- Valid character sets are ones GLib's g_convert() accepts, typically GNU
-- iconv's character sets.
-- @param text The text to convert.
-- @param to The character set to convert to.
-- @param from The character set to convert from.
function iconv(text, to, from) end
