-- Copyright 2007-2008 Mitchell Foral mitchell<att>caladbolg.net. See LICENSE.

---
-- Defines the key commands used by the Textadept key command manager.
-- For non-ascii keys, see textadept.keys for string aliases.
-- This set of key commands is pretty standard among other text editors.
module('textadept.key_commands_std', package.seeall)

--[[
  C:     B   D       H   J K L           R     U
  A:   A B C D E F G H   J K L M N   P Q R S T U V W X Y Z
  CS:  A B C D   F G H   J K L M N O   Q R   T U V   X Y Z
  SA:  A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
  CA:  A B C D E F G H   J K L M N O   Q R S T U V W X Y Z
  CSA: A B C D E F G H   J K L M N O P Q R S T U V W X Y Z
]]--

---
-- Global container that holds all key commands.
-- @class table
-- @name keys
_G.keys = {}
local keys = keys

keys.clear_sequence = 'esc'

local b, v = 'buffer', 'view'
local t = textadept

keys.ct   = {} -- Textadept command chain
keys.ct.e = {} -- Enclose in... chain
keys.ct.s = {} -- Select in... chain
keys.ct.v = {} -- Buffer view chain

-- File
keys.cn  = { t.new_buffer   }
keys.co  = { t.io.open      }
-- TODO: { 'reload', b }
keys.cs  = { 'save', b      }
keys.css = { 'save_as', b   }
keys.cw  = { 'close', b     }
keys.csw = { t.io.close_all }
-- TODO: { t.io.load_session } after prompting with open dialog
-- TODO: { t.io.save_session } after prompting with save dialog
-- TODO: quit

-- Edit
local m_editing = _m.textadept.editing
-- Undo is cz.
-- Redo is cy.
-- Cut is cx.
-- Copy is cc.
-- Paste is cv.
-- Delete is delete.
-- Select All is ca.
keys.ce     = { m_editing.match_brace              }
keys.cse    = { m_editing.match_brace, 'select'    }
keys['c\n'] = { m_editing.autocomplete_word, '%w_' }
keys.cq     = { m_editing.block_comment            }
-- TODO: { m_editing.current_word, 'delete' }
-- TODO: { m_editing.transpose_chars }
-- TODO: { m_editing.squeeze }
-- TODO: { m_editing.move_line, 'up' }
-- TODO: { m_editing.move_line, 'down' }
-- TODO: { m_editing.convert_indentation }
-- TODO: { m_editing.smart_cutcopy }
-- TODO: { m_editing.smart_cutcopy, 'copy' }
-- TODO: { m_editing.smart_paste }
-- TODO: { m_editing.smart_paste, 'cycle' }
-- TODO: { m_editing.smart_paste, 'reverse' }
-- TODO: { m_editing.ruby_exec }
-- TODO: { m_editing.lua_exec }
keys.ct.e.t    = { m_editing.enclose, 'tag'                }
keys.ct.e.st   = { m_editing.enclose, 'single_tag'         }
keys.ct.e['"'] = { m_editing.enclose, 'dbl_quotes'         }
keys.ct.e["'"] = { m_editing.enclose, 'sng_quotes'         }
keys.ct.e['('] = { m_editing.enclose, 'parens'             }
keys.ct.e['['] = { m_editing.enclose, 'brackets'           }
keys.ct.e['{'] = { m_editing.enclose, 'braces'             }
keys.ct.e.c    = { m_editing.enclose, 'chars'              }
keys.ct.e.g    = { m_editing.grow_selection, 1             }
keys.ct.s.e    = { m_editing.select_enclosed               }
keys.ct.s.t    = { m_editing.select_enclosed, 'tags'       }
keys.ct.s['"'] = { m_editing.select_enclosed, 'dbl_quotes' }
keys.ct.s["'"] = { m_editing.select_enclosed, 'sng_quotes' }
keys.ct.s['('] = { m_editing.select_enclosed, 'parens'     }
keys.ct.s['['] = { m_editing.select_enclosed, 'brackets'   }
keys.ct.s['{'] = { m_editing.select_enclosed, 'braces'     }
keys.ct.s.w    = { m_editing.current_word, 'select'        }
keys.ct.s.l    = { m_editing.select_line                   }
keys.ct.s.p    = { m_editing.select_paragraph              }
keys.ct.s.b    = { m_editing.select_indented_block         }
keys.ct.s.s    = { m_editing.select_scope                  }

-- Search
keys.cf = { t.find.focus        } -- find/replace
-- Find Next is an when find pane is focused.
-- Find Prev is ap when find pane is focused.
-- Replace is ar when find pane is focused.
keys.cg = { m_editing.goto_line }

-- Tools
keys['f2'] = { t.command_entry.focus }
-- Snippets
local m_snippets = _m.textadept.lsnippets
keys.ci   = { m_snippets.insert         }
keys.csi  = { m_snippets.prev           }
keys.cai  = { m_snippets.cancel_current }
keys.casi = { m_snippets.list           }
keys.ai   = { m_snippets.show_style     }
-- Multiple Line Editing
local m_mlines = _m.textadept.mlines
keys.cm    = {}
keys.cm.a  = { m_mlines.add             }
keys.cm.sa = { m_mlines.add_multiple    }
keys.cm.r  = { m_mlines.remove          }
keys.cm.sr = { m_mlines.remove_multiple }
keys.cm.u  = { m_mlines.update          }
keys.cm.c  = { m_mlines.clear           }

-- Buffers
keys['c\t']  = { 'goto_buffer', v, 1, false  }
keys['cs\t'] = { 'goto_buffer', v, -1, false }
local function toggle_setting(setting)
  local state = buffer[setting]
  if type(state) == 'boolean' then
    buffer[setting] = not state
  elseif type(state) == 'number' then
    buffer[setting] = buffer[setting] == 0 and 1 or 0
  end
  t.events.update_ui() -- for updating statusbar
end
keys.ct.v.e     = { toggle_setting, 'view_eol'           }
keys.ct.v.w     = { toggle_setting, 'wrap_mode'          }
keys.ct.v.i     = { toggle_setting, 'indentation_guides' }
keys.ct.v['\t'] = { toggle_setting, 'use_tabs'           }
keys.ct.v[' ']  = { toggle_setting, 'view_ws'            }
keys['f5']      = { 'colourise', b, 0, -1                }

-- Views
keys['ca\t']  = { t.goto_view, 1, false                      }
keys['csa\t'] = { t.goto_view, -1, false                     }
keys.ct.ss    = { 'split', v                                 } -- vertical
keys.ct.s     = { 'split', v, false                          } -- horizontal
keys.ct.w     = { function() view:unsplit() return true end  }
keys.ct.sw    = { function() while view:unsplit() do end end }
-- TODO: { function() view.size = view.size + 10 end  }
-- TODO: { function() view.size = view.size - 10 end  }

-- Project Manager
local function pm_activate(text) t.pm.entry_text = text t.pm.activate() end
keys.csp = { function() if t.pm.width > 0 then t.pm.toggle_visible() end end }
keys.cp  = { function()
  if t.pm.width == 0 then t.pm.toggle_visible() end
  t.pm.focus()
end }
keys.cap = {
  c = { pm_activate, 'ctags'   },
  b = { pm_activate, 'buffers' },
  f = { pm_activate, '/'       },
-- TODO: { pm_activate, 'macros' }
  m = { pm_activate, 'modules' },
}

-- Miscellaneous not in standard menu.
-- Recent files.
local RECENT_FILES = 1
t.events.add_handler('user_list_selection',
  function(type, text) if type == RECENT_FILES then t.io.open(text) end end)
keys.ao = { function()
  local buffer = buffer
  local list = ''
  local sep = buffer.auto_c_separator
  buffer.auto_c_separator = ('|'):byte()
  for _, filename in ipairs(t.io.recent_files) do
    list = filename..'|'..list
  end
  buffer:user_list_show( RECENT_FILES, list:sub(1, -2) )
  buffer.auto_c_separator = sep
end }
