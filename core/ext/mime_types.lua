-- Copyright 2007-2008 Mitchell Foral mitchell<att>caladbolg.net. See LICENSE.

--- Handles file-specific settings (based on file extension).
module('textadept.mime_types', package.seeall)

---
-- [Local table] Language names with their associated lexers.
-- @class table
-- @name languages
local languages = {
  as = 'actionscript',
  ada = 'ada',
  antlr = 'antlr',
  apdl = 'apdl',
  applescript = 'applescript',
  asp = 'asp',
  awk = 'awk',
  batch = 'batch',
  cpp = 'cpp',
  csharp = 'csharp',
  css = 'css',
  d = 'd',
  diff = 'diff',
  django = 'django',
  eiffel = 'eiffel',
  erlang = 'erlang',
  forth = 'forth',
  fortran = 'fortran',
  gettext = 'gettext',
  gnuplot = 'gnuplot',
  groovy = 'groovy',
  haskell = 'haskell',
  html = 'html',
  ini = 'ini',
  io = 'io',
  java = 'java',
  js = 'javascript',
  latex = 'latex',
  lisp = 'lisp',
  lua = 'lua',
  makefile = 'makefile',
  maxima = 'maxima',
  mysql = 'mysql',
  objc = 'objective_c',
  pascal = 'pascal',
  php = 'php',
  pike = 'pike',
  postscript = 'postscript',
  props = 'props',
  python = 'python',
  ragel = 'ragel',
  rebol = 'rebol',
  rhtml = 'rhtml',
  ruby = 'ruby',
  scheme = 'scheme',
  shell = 'shellscript',
  smalltalk = 'smalltalk',
  verilog = 'verilog',
  vhdl = 'vhdl',
  vb = 'visualbasic',
  xml = 'xml'
}

local l = languages
---
-- [Local table] File extensions with their associated languages.
-- @class table
-- @name extensions
local extensions = {
  -- Actionscript
  as = l.as,
  -- Ada
  ada = l.ada, adb = l.ada, ads = l.ada,
  -- ANTLR
  g = l.antlr,
  -- APDL
  ans = l.apdl,
  inp = l.apdl,
  mac = l.apdl,
  -- Applescript
  applescript = l.applescript,
  -- ASP
  asa = l.asp, asp = l.asp,
  -- AWK
  awk = l.awk,
  -- Batch
  bat = l.batch,
  cmd = l.batch,
  -- C/C++
  c = l.cpp, cpp = l.cpp, cxx = l.cpp,
  h = l.cpp, hh = l.cpp, hpp = l.cpp,
  -- C#
  cs = l.csharp,
  -- CSS
  css = l.css,
  -- D
  d = l.d,
  -- Diff
  diff = l.diff,
  patch = l.diff,
  -- Eiffel
  e = l.eiffel,
  -- Erlang
  erl = l.erlang,
  -- Forth
  f = l.forth,
  -- Fortran
  ['for'] = l.fortran, fort = l.fortran, f77 = l.fortran, f90 = l.fortran,
  -- Gettext
  po = l.gettext, pot = l.gettext,
  -- GNUPlot
  dem = l.gnuplot,
  plt = l.gnuplot,
  -- Goovy
  groovy = l.groovy, grv = l.groovy,
  -- Haskell
  hs = l.haskell,
  -- HTML
  htm = l.html, html = l.html,
  shtm = l.html, shtml = l.html,
  -- ini
  ini = l.ini,
  reg = l.ini,
  -- Io
  io = l.io,
  -- Java
  bsh = l.java,
  java = l.java,
  -- Javascript
  js = l.js,
  -- Latex
  ltx = l.latex,
  tex = l.latex,
  sty = l.latex,
  -- Lisp
  el = l.lisp,
  lisp = l.lisp,
  lsp = l.lisp,
  -- Lua
  lua = l.lua,
  -- Makefile
  iface = l.makefile,
  mak = l.makefile, makefile = l.makefile, Makefile = l.makefile,
  -- Maxima
  maxima = l.maxima,
  -- MySQL
  sql = l.mysql,
  -- Objective C
  m = l.objc,
  objc = l.objc,
  -- Pascal
  dpk = l.pascal, dpr = l.pascal,
  pas = l.pascal,
  -- PHP
  inc = l.php,
  php = l.php, php3 = l.php, php4 = l.php, phtml = l.php,
  -- Pike
  pike = l.pike, pmod = l.pike,
  -- Postscript
  eps = l.postscript,
  ps = l.postscript,
  -- Properties
  props = l.props, properties = l.props,
  -- Python
  sc = l.python,
  py = l.python, pyw = l.python,
  -- Rebol
  r = l.rebol,
  -- RHTML
  rhtml = l.rhtml,
  -- Ruby
  rb = l.ruby, rbw = l.ruby,
  -- Ragel
  rl = l.ragel,
  -- Scheme
  scm = l.scheme,
  -- Shell
  bash = l.shell,
  csh = l.shell,
  sh = l.shell,
  -- Smalltalk
  changes = l.smalltalk,
  st = l.smalltalk, sources = l.smalltalk,
  -- Verilog
  v = l.verilog, ver = l.verilog,
  -- VHDL
  vh = l.vhdl, vhd = l.vhdl, vhdl = l.vhdl,
  -- Visual Basic
  asa = l.vb,
  bas = l.vb,
  cls = l.vb, ctl = l.vb,
  dob = l.vb, dsm = l.vb, dsr = l.vb,
  frm = l.vb,
  pag = l.vb,
  vb = l.vb, vba = l.vb, vbs = l.vb,
  -- XML
  xhtml = l.xml, xml = l.xml, xsd = l.xml, xsl = l.xml, xslt = l.xml
}

---
-- [Local table] Shebang words and their associated languages.
-- @class table
-- @name shebangs
local shebangs = {
  awk = l.awk,
  lua = l.lua,
  php = l.php,
  python = l.python,
  ruby = l.ruby,
  sh = l.shell,
}

---
-- [Local function] Sets the buffer's lexer language based on a filename.
-- @param filename The filename used to set the lexer language.
-- @return boolean indicating whether or not a lexer language was set.
local function set_lexer_from_filename(filename)
  local lexer
  if filename then
    local ext = filename:match('[^/]+$'):match('[^.]+$')
    lexer = extensions[ext]
  end
  buffer:set_lexer_language(lexer or 'container')
  return lexer
end

---
-- [Local function] Sets the buffer's lexer language based on a shebang line.
local function set_lexer_from_sh_bang()
  local lexer
  local line = buffer:get_line(0)
  if line:match('^#!') then
    line = line:gsub('[\\/]', ' ')
    for word in line:gmatch('%S+') do
      lexer = shebangs[word]
      if lexer then break end
    end
    buffer:set_lexer_language(lexer)
  end
end

---
-- [Local function] Loads a language module based on a filename (if it hasn't
-- been loaded already).
-- @param filename The filename used to load a language module from.
local function load_language_module_from_filename(filename)
  if not filename then return end
  local ext = filename:match('[^/]+$'):match('[^.]+$')
  local lang = extensions[ext]
  if lang then
    local ret, err = pcall(require, lang)
    if ret then
      _m[lang].set_buffer_properties()
    elseif not ret and not err:match("^module '"..lang.."' not found:") then
      textadept.events.error(err)
    end
  end
end

---
-- [Local function] Performs actions suitable for a new buffer.
-- Sets the buffer's lexer language and loads the language module.
local function handle_new()
  local buffer = buffer
  if not set_lexer_from_filename(buffer.filename) then
    set_lexer_from_sh_bang()
  end
  load_language_module_from_filename(buffer.filename)
end

---
-- [Local function] Performs actions suitable for when buffers are switched.
-- Sets the buffer's lexer language.
local function handle_switch()
  if not set_lexer_from_filename(buffer.filename) then
    set_lexer_from_sh_bang()
  end
end

local events = textadept.events
events.add_handler('file_opened', handle_new)
events.add_handler('file_saved_as', handle_new)
events.add_handler('buffer_switch', handle_switch)
events.add_handler('view_new', handle_switch)
