-- Copyright 2007-2009 Mitchell Foral mitchell<att>caladbolg.net. See LICENSE.

local textadept = _G.textadept
local locale = _G.locale

---
-- Module for running/executing source files.
module('_m.textadept.run', package.seeall)

---
-- Executes the command line parameter and prints the output to Textadept.
-- @param command The command line string.
--   It can have the following macros:
--     * %(filepath) The full path of the current file.
--     * %(filedir) The current file's directory path.
--     * %(filename) The name of the file including extension.
--     * %(filename_noext) The name of the file excluding extension.
function execute(command)
  local filepath = textadept.iconv(buffer.filename, _CHARSET, 'UTF-8')
  local filedir, filename
  if filepath:find('[/\\]') then
    filedir, filename = filepath:match('^(.+[/\\])([^/\\]+)$')
  else
    filedir, filename = '', filepath
  end
  local filename_noext = filename:match('^(.+)%.')
  command = command:gsub('%%%b()', {
    ['%(filepath)'] = filepath,
    ['%(filedir)'] = filedir,
    ['%(filename)'] = filename,
    ['%(filename_noext)'] = filename_noext,
  })
  local current_dir = lfs.currentdir()
  lfs.chdir(filedir)
  local p = io.popen(command..' 2>&1')
  local out = p:read('*all')
  p:close()
  lfs.chdir(current_dir)
  textadept.print(textadept.iconv('> '..command..'\n'..out, 'UTF-8', _CHARSET))
  buffer:goto_pos(buffer.length)
end

---
-- File extensions and their associated 'compile' actions.
-- Each key is a file extension whose value is a either a command line string to
-- execute or a function returning one.
-- @class table
-- @name compile_commands
compile_commands = {
  c = 'gcc -pedantic -Os -o "%(filename_noext)" %(filename)',
  cpp = 'g++ -pedantic -Os -o "%(filename_noext)" %(filename)',
  java = 'javac "%(filename)"'
}

---
-- Compiles the file as specified by its extension in the compile_commands
-- table.
-- @see compile_commands
function compile()
  if not buffer.filename then return end
  local action = compile_commands[buffer.filename:match('[^.]+$')]
  if action then execute(type(action) == 'function' and action() or action) end
end

---
-- File extensions and their associated 'go' actions.
-- Each key is a file extension whose value is either a command line string to
-- execute or a function returning one.
-- @class table
-- @name run_commands
run_commands = {
  c = '%(filedir)%(filename_noext)',
  cpp = '%(filedir)%(filename_noext)',
  java = function()
      local buffer = buffer
      local text = buffer:get_text()
      local s, e, package
      repeat
        s, e, package = text:find('package%s+([^;]+)', e or 1)
      until not s or buffer:get_style_name(buffer.style_at[s]) ~= 'comment'
      if package then
        local classpath = ''
        for dot in package:gmatch('%.') do classpath = classpath..'../' end
        return 'java -cp '..(WIN32 and '%CLASSPATH%;' or '$CLASSPATH:')..
          classpath..'../ '..package..'.%(filename_noext)'
      else
        return 'java %(filename_noext)'
      end
    end,
  lua = 'lua %(filename)',
  pl = 'perl %(filename)',
  php = 'php -f %(filename)',
  py = 'python %(filename)',
  rb = 'ruby %(filename)',
}

---
-- Runs/executes the file as specified by its extension in the run_commands
-- table.
-- @see run_commands
function run()
  if not buffer.filename then return end
  local action = run_commands[buffer.filename:match('[^.]+$')]
  if action then execute(type(action) == 'function' and action() or action) end
end

---
-- [Local table] A table of error string details.
-- Each entry is a table with the following fields:
--   pattern: the Lua pattern that matches a specific error string.
--   filename: the index of the Lua capture that contains the filename the error
--     occured in.
--   line: the index of the Lua capture that contains the line number the error
--     occured on.
--   message: [Optional] the index of the Lua capture that contains the error's
--     message. A call tip will be displayed if a message was captured.
-- When an error message is double-clicked, the user is taken to the point of
--   error.
-- @class table
-- @name error_details
local error_details = {
  -- c, c++, and java errors and warnings have the same format as ruby ones
  lua = {
    pattern = '^lua: (.-):(%d+): (.+)$',
    filename = 1, line = 2, message = 3
  },
  perl = {
    pattern = '^(.+) at (.-) line (%d+)',
    message = 1, filename = 2, line = 3
  },
  php_error = {
    pattern = '^Parse error: (.+) in (.-) on line (%d+)',
    message = 1, filename = 2, line = 3
  },
  php_warning = {
    pattern = '^Warning: (.+) in (.-) on line (%d+)',
    message = 1, filename = 2, line = 3
  },
  python = {
    pattern = '^%s*File "([^"]+)", line (%d+)',
    filename = 1, line = 2
  },
  ruby = {
    pattern = '^(.-):(%d+): (.+)$',
    filename = 1, line = 2, message = 3
  },
}

---
-- When the user double-clicks an error message, go to the line in the file
-- the error occured at and display a calltip with the error message.
-- @param pos The position of the caret.
-- @param line_num The line double-clicked.
-- @see error_details
function goto_error(pos, line_num)
  local type = buffer._type
  if type == locale.MESSAGE_BUFFER or type == locale.ERROR_BUFFER then
    line = buffer:get_line(line_num)
    for _, error_detail in pairs(error_details) do
      local captures = { line:match(error_detail.pattern) }
      if #captures > 0 then
        local lfs = require 'lfs'
        local utf8_filename = captures[error_detail.filename]
        local filename = textadept.iconv(utf8_filename, _CHARSET, 'UTF-8')
        if lfs.attributes(filename) then
          textadept.io.open(utf8_filename)
          _m.textadept.editing.goto_line(captures[error_detail.line])
          local msg = captures[error_detail.message]
          if msg then buffer:call_tip_show(buffer.current_pos, msg) end
        else
          error(string.format(
            locale.M_TEXTADEPT_RUN_FILE_DOES_NOT_EXIST, utf8_filename))
        end
        break
      end
    end
  end
end
textadept.events.add_handler('double_click', goto_error)
