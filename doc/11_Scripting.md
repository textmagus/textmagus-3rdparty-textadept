# Scripting

Textadept has superb support for editing Lua code. Syntax autocomplete and
LuaDoc is available for many Textadept objects as well as Lua's standard
libraries. See the [`lua` module documentation][] for more information.

![Adeptsense ta](images/adeptsense_ta.png)
&nbsp;&nbsp;&nbsp;&nbsp;
![Adeptsense tadoc](images/adeptsense_tadoc.png)

[`lua` module documentation]: api/_M.lua.html

## LuaDoc and Examples

Textadept's API is heavily documented. The [API docs][] are the ultimate
resource on scripting Textadept. There are of course abundant scripting examples
since Textadept is mostly written in Lua.

[API docs]: api/index.html

### Generating LuaDoc

You can generate API documentation for your own modules using the
`doc/markdowndoc.lua` [LuaDoc][] module:

    luadoc -d . --doclet _HOME/doc/markdowndoc [module(s)]

or

    luadoc -d . -t template_dir --doclet _HOME/doc/markdowndoc [module(s)]

where `_HOME` is where Textadept is installed and `template_dir` is an optional
template directory that contains two Markdown files: `.header.md` and
`.footer.md`. (See `doc/.header.md` and `doc/.footer.md` for examples.) You must
have [Discount][] installed.

[LuaDoc]: http://keplerproject.github.com/luadoc/
[Discount]: http://www.pell.portland.or.us/~orc/Code/discount/

## Lua Configuration

[Lua 5.2][] is built into Textadept. It has the same configuration (`luaconf.h`)
as vanilla Lua with the following exceptions:

* `TA_LUA_PATH` and `TA_LUA_CPATH` are the environment variable used in place of
  the usual `LUA_PATH` and `LUA_CPATH`.
* `LUA_ROOT` is `/usr/` in Linux systems instead of `/usr/local/`.
* All compatibility flags for Lua 5.1 are turned off. (`LUA_COMPAT_UNPACK`,
  `LUA_COMPAT_LOADERS`, `LUA_COMPAT_LOG10`, `LUA_COMPAT_LOADSTRING`,
  `LUA_COMPAT_MAXN`, and `LUA_COMPAT_MODULE`.)

[Lua 5.2]: http://www.lua.org/manual/5.2/

## Scintilla

The editing component used by Textadept is [Scintilla][]. The [buffer][] part of
Textadept's API is derived from the [Scintilla API][] so any C/C++ code using
Scintilla calls can be ported to Lua without too much trouble.

[Scintilla]: http://scintilla.org
[buffer]: api/buffer.html
[Scintilla API]: http://scintilla.org/ScintillaDoc.html

## Textadept Structure

Because Textadept is mostly written in Lua, its Lua scripts have to be stored in
an organized folder structure.

### Core

Textadept's core Lua modules are contained in `core/`. These are absolutely
necessary in order for the application to run. They are responsible for
Textadept's Lua to C interface, event structure, file input/output, and
localization.

### Lexers

Lexer Lua modules are responsible for the syntax highlighting of source code.
They are located in `lexers/`.

### Modules

Editor Lua modules are contained in `modules/`. These provide advanced text
editing capabilities and can be available for all programming languages or
targeted at specific ones.

### Themes

Built-in themes to customize the look and behavior of Textadept are located in
`themes/`.

### User

User Lua modules are contained in the `~/.textadept/` folder. This folder may
contain `lexers/`, `modules/`, and `themes/` subdirectories.

### GTK

The `etc/`, `lib/`, and `share/` directories are used by GTK and only appear in
the Win32 and Mac OSX packages.