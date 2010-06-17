-- Copyright 2007-2010 Mitchell Foral mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for built-in functions in the
-- global _m table.

---
-- A table of loaded modules.
module('_m')

-- Markdown:
-- ## Overview
--
-- Modules utilize the Lua 5.1 package model. It is recommended to put all
-- modules in your `~/.textadept/modules/` directory. A module consists of a
-- single directory with an `init.lua` script to load any additional Lua files
-- (typically in the same location). Essentially there are two classes of
-- modules: generic and language-specific.
--
-- ## Generic Modules
--
-- This class of modules is usually available globally for programming in all
-- languages. An example is the [`_m.textadept`][m_textadept] module which adds
-- a wide variety of text editing capabilities to Textadept.
--
-- [m_textadept]: ../modules/_m.textadept.html
--
-- ## Language-specific Modules
--
-- Each module of this class of modules is named after a language lexer in
-- `lexers/` and is usually available only for editing code in that particular
-- programming language. Examples are the [`_m.cpp`][m_cpp] and
-- [`_m.lua`][m_lua] modules which provide special editing features for the
-- C/C++ and Lua languages respectively.
--
-- [m_cpp]: ../modules/_m.cpp.html
-- [m_lua]: ../modules/_m.lua.html
--
-- Note: While language-specific modules can only be used by files of that
-- language, they persist in Textadept's Lua state. Because of this, it is not
-- recommended to set global functions or variables and depend on them, as they
-- may be inadvertantly overwritten. Keep these inside the module.
--
-- ## Loading Modules
--
-- Generic modules can be loaded using `require`:
--
--     require 'module_name'
--
-- Language-specific modules are automatically loaded when a file of that
-- language is loaded or a buffer's lexer is set to that language.
--
-- ## Modules and Key Commands
--
-- When assigning [key commands][key_commands] to module functions, do not
-- forget to do so AFTER the function has been defined. Typically key commands
-- are placed at the end of files, like `commands.lua` in language-specific
-- modules.
--
-- [key_commands]: ../modules/_m.textadept.keys.html

---
-- This module contains no functions.
function no_functions() end
