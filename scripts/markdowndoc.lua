-- Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.

local ipairs, type = ipairs, type
local io_open, io_popen = io.open, io.popen
local string_format, string_rep = string.format, string.rep
local table_concat = table.concat

---
-- Markdown doclet for Luadoc.
-- Requires Discount (http://www.pell.portland.or.us/~orc/Code/discount/).
-- @usage luadoc -d [output_path] -doclet path/to/markdowndoc [file(s)]
module('markdowndoc')

local NAVFILE = '%s* [%s](%s)\n'
local FUNCTION = '<a id="%s" />\n### `%s` (%s)\n\n'
--local FUNCTION = '### `%s` (%s)\n\n'
local DESCRIPTION = '> %s\n\n'
local LIST_TITLE = '> %s:\n\n'
local PARAM = '> * `%s`: %s\n'
local USAGE = '> * `%s`\n'
local RETURN = '> * %s\n'
local SEE = '> * [`%s`](#%s)\n'
local TABLE = '<a id="%s" />\n### `%s`\n\n'
--local TABLE = '### `%s`\n\n'
local FIELD = '> * `%s`: %s\n'
local HTML = [[
  <!doctype html>
  <html>
    <head>
      <title>%(title)</title>
      <link rel="stylesheet" href="../style.css" type="text/css" />
      <meta charset="utf-8" />
    </head>
    <body>
      <div id="content">
        <div id="nav">
          <div class="title">Modules</div>
          %(nav)
        </div>
        <div id="toc">
          <div class="title">Contents</div>
          %(toc)
        </div>
        <div id="main">
          %(main)
        </div>
      </div>
    </body>
  </html>
]]

-- Writes LuaDoc hierarchical module navigation to the given file.
-- @param f The navigation file being written to.
-- @param list The module list.
-- @param parent String parent module with a trailing '.' for sub-modules in
--   order to generate full page links.
local function write_nav(f, list, parent)
  if not parent then parent = '' end
  local level = 0
  for _ in parent:gmatch('%.') do level = level + 1 end
  for _, name in ipairs(list) do
    f:write(string_format(NAVFILE, string_rep(' ', level * 4), name,
                          parent..name..'.html'))
    if list[name] then
      f:write('\n')
      write_nav(f, list[name], parent..name..'.')
    end
  end
end

-- Writes a LuaDoc description to the given file.
-- @param f The markdown file being written to.
-- @param description The description.
local function write_description(f, description)
  f:write(string_format(DESCRIPTION, description))
end

-- Writes a LuaDoc list to the given file.
-- @param f The markdown file being written to.
-- @param title The title of the list.
-- @param fmt The format of a list item.
-- @param list The LuaDoc list.
local function write_list(f, title, fmt, list)
  if not list or #list == 0 then return end
  if type(list) == 'string' then list = { list } end
  f:write(string_format(LIST_TITLE, title))
  for _, value in ipairs(list) do
    f:write(string_format(fmt, value, value))
  end
  f:write('\n')
end

-- Writes a LuaDoc hashmap to the given file.
-- @param f The markdown file being written to.
-- @param title The title of the hashmap.
-- @param fmt The format of a hashmap item.
-- @param list The LuaDoc hashmap.
local function write_hashmap(f, title, fmt, hashmap)
  if not hashmap or #hashmap == 0 then return end
  f:write(string_format(LIST_TITLE, title))
  for _, name in ipairs(hashmap) do
    f:write(string_format(fmt, name, hashmap[name] or ''))
  end
  f:write('\n')
end

-- Called by LuaDoc to process a doc object.
-- @param doc The LuaDoc doc object.
function start(doc)
  local modules, files = doc.modules, doc.files

  -- Create the navigation list.
  local hierarchy = {}
  for _, name in ipairs(modules) do
    local parent, self = name:match('^(.-)%.?([^.]+)$')
    local h = hierarchy
    for table in parent:gmatch('[^.]+') do
      if not h[table] then h[table] = {} end
      h = h[table]
    end
    h[#h + 1] = self
  end
  local navfile = options.output_dir..'/api/.nav.md'
  local f = io_open(navfile, 'wb')
  write_nav(f, hierarchy)
  f:close()
  local p = io_popen('markdown "'..navfile..'"')
  local nav = p:read('*all')
  p:close()

  -- Create a map of doc objects to file names so their Markdown doc comments
  -- can be extracted.
  local filedocs = {}
  for _, name in ipairs(files) do filedocs[files[name].doc] = name end

  -- Loop over modules, creating Markdown documents.
  for _, name in ipairs(modules) do
    local module = modules[name]
    local filename = filedocs[module.doc]

    local mdfile = options.output_dir..'/api/'..name..'.md'
    local f = io_open(mdfile, 'wb')

    -- Write the header and description.
    f:write('# ', name, '\n\n')
    f:write(module.description, '\n\n')

    -- Extract any Markdown doc comments and insert them.
    -- Markdown doc comments must immediately proceed a 'module' declaration
    -- (excluding blank lines), start with '-- Markdown:', and end on a blank or
    -- uncommented line.
    if filename then
      local module_declaration, markdown = false, false
      local module_file = io_open(filename, 'rb')
      for line in module_file:lines() do
        if not module_declaration and line:find('^module') then
          module_declaration = true
        elseif module_declaration and not markdown and line ~= '' then
          if line ~= '-- Markdown:' then break end
          markdown = true
        elseif markdown then
          line = line:match('^%-%-%s?(.*)$')
          if not line then break end
          f:write(line, '\n')
        end
      end
      module_file:close()
    end
    f:write('\n')
    f:write('- - -\n\n')

    -- Write functions.
    local funcs = module.functions
    if #funcs > 0 then
      f:write('## Functions\n\n')
      f:write('- - -\n\n')
      for _, fname in ipairs(funcs) do
        local func = funcs[fname]
        f:write(string_format(FUNCTION, func.name, func.name,
                              table_concat(func.param, ', '):gsub('_', '\\_')))
        write_description(f, func.description)
        write_hashmap(f, 'Parameters', PARAM, func.param)
        write_list(f, 'Usage', USAGE, func.usage)
        write_list(f, 'Return', RETURN, func.ret)
        write_list(f, 'See also', SEE, func.see)
        f:write('- - -\n\n')
      end
      f:write('\n')
    end

    -- Write tables.
    local tables = module.tables
    if #tables > 0 then
      f:write('## Tables\n\n')
      f:write('- - -\n\n')
      for _, tname in ipairs(tables) do
        local tbl = tables[tname]
        f:write(string_format(TABLE, tbl.name, tbl.name))
        write_description(f, tbl.description)
        write_hashmap(f, 'Fields', FIELD, tbl.field)
        write_list(f, 'Usage', USAGE, tbl.usage)
        write_list(f, 'See also', SEE, tbl.see)
        f:write('- - -\n\n')
      end
    end

    f:close()

    -- Write HTML.
    local p = io_popen('markdown -f toc -T "'..mdfile..'"')
    local toc, main = p:read('*all'):match('^(.-\n</ul>\n)(.+)$')
    p:close()
    toc = toc:gsub('(<a.-)%b()(</a>)', '%1%2') -- strip function parameters
    f = io_open(options.output_dir..'/api/'..name..'.html', 'wb')
    local html = HTML:gsub('%%%(([^)]+)%)', {
      title = name..' - Textadept API', nav = nav, toc = toc, main = main
    })
    f:write(html)
    f:close()
  end
end
