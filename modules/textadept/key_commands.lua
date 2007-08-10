-- Copyright 2007 Mitchell Foral mitchell<att>caladbolg.net. See LICENSE.

---
-- Defines the key commands used by the Textadept key command manager.
module('_m.textadept.key_commands', package.seeall)

--[[
  C:               G                   Q
  A:   A   C       G     J K L     O   Q R         W X   Z
  CS:      C D     G     J   L         Q R S T U   W
  SA:  A   C D E   G H I J K L M   O   Q R S T     W X   Z
  CA:  A   C       G H   J K L     O   Q R S T   V W X Y Z
  CSA:     C D     G H   J K L     O   Q R S T U   W X   Z
]]--

---
-- Global container that holds all key commands.
-- @class table
-- @name keys
_G.keys = {}
local keys = keys

keys.clear_sequence = 'esc'

local b, v = 'buffer', 'view'
local textadept = textadept

keys.cf  = { 'char_right',        b }
keys.csf = { 'char_right_extend', b }
keys.af  = { 'word_right',        b }
keys.saf = { 'word_right_extend', b }
keys.cb  = { 'char_left',         b }
keys.csb = { 'char_left_extend',  b }
keys.ab  = { 'word_left',         b }
keys.sab = { 'word_left_extend',  b }
keys.cn  = { 'line_down',         b }
keys.csn = { 'line_down_extend',  b }
keys.cp  = { 'line_up',           b }
keys.csp = { 'line_up_extend',    b }
keys.ca  = { 'vc_home',           b }
keys.csa = { 'home_extend',       b }
keys.ce  = { 'line_end',          b }
keys.cse = { 'line_end_extend',   b }
keys.cv  = { 'page_down',         b }
keys.csv = { 'page_down_extend',  b }
keys.av  = { 'para_down',         b }
keys.sav = { 'para_down_extend',  b }
keys.cy  = { 'page_up',           b }
keys.csy = { 'page_up_extend',    b }
keys.ay  = { 'para_up',           b }
keys.say = { 'para_up_extend',    b }
keys.ch  = { 'delete_back',       b }
keys.ah  = { 'del_word_left',     b }
keys.cd  = { 'clear',             b }
keys.ad  = { 'del_word_right',    b }

keys.csaf = { 'char_right_rect_extend', b }
keys.csab = { 'char_left_rect_extend',  b }
keys.csan = { 'line_down_rect_extend',  b }
keys.csap = { 'line_up_rect_extend',    b }
keys.csaa = { 'vc_home_rect_extend',    b }
keys.csae = { 'line_end_rect_extend',   b }
keys.csav = { 'page_down_rect_extend',  b }
keys.csay = { 'page_up_rect_extend',    b }

local m_snippets = _m.textadept.snippets
keys.ci   = { m_snippets.insert           }
keys.csi  = { m_snippets.cancel_current   }
keys.cai  = { m_snippets.list             }
keys.ai   = { m_snippets.show_scope       }

local m_editing = _m.textadept.editing
keys.cm    = { m_editing.match_brace              }
keys.csm   = { m_editing.match_brace, 'select'    }
keys['c '] = { m_editing.autocomplete_word, '%w_' }
keys.cl    = { m_editing.goto_line                }
keys.ck    = { m_editing.smart_cutcopy,           }
keys.csk   = { m_editing.smart_cutcopy, 'copy'    }
keys.cu    = { m_editing.smart_paste,             }
keys.au    = { m_editing.smart_paste, 'cycle'     }
keys.sau   = { m_editing.smart_paste, 'reverse'   }
keys.cw    = { m_editing.current_word, 'delete'   }
keys.at    = { m_editing.transpose_chars          }
keys.csh   = { m_editing.squeeze,                 }
keys.cj    = { m_editing.join_lines               }
keys.cau   = { m_editing.move_line, 'up'          }
keys.cad   = { m_editing.move_line, 'down'        }
keys.csai  = { m_editing.convert_indentation      }
keys.cae   = { -- code execution
  r = { m_editing.ruby_exec },
  l = { m_editing.lua_exec  }
}
keys.ae = { -- enclose in...
  t      = { m_editing.enclose, 'tag'        },
  st     = { m_editing.enclose, 'single_tag' },
  ['s"'] = { m_editing.enclose, 'dbl_quotes' },
  ["'"]  = { m_editing.enclose, 'sng_quotes' },
  ['(']  = { m_editing.enclose, 'parens'     },
  ['[']  = { m_editing.enclose, 'brackets'   },
  ['{']  = { m_editing.enclose, 'braces'     },
  c      = { m_editing.enclose, 'chars'      },
}
keys.as = { -- select in...
  e      = { m_editing.select_enclosed               },
  t      = { m_editing.select_enclosed, 'tags'       },
  ['s"'] = { m_editing.select_enclosed, 'dbl_quotes' },
  ["'"]  = { m_editing.select_enclosed, 'sng_quotes' },
  ['(']  = { m_editing.select_enclosed, 'parens'     },
  ['[']  = { m_editing.select_enclosed, 'brackets'   },
  ['{']  = { m_editing.select_enclosed, 'braces'     },
  w      = { m_editing.current_word,    'select'     },
  l      = { m_editing.select_line                   },
  p      = { m_editing.select_paragraph              },
  i      = { m_editing.select_indented_block         },
  s      = { m_editing.select_scope                  },
  g      = { m_editing.grow_selection, 1             },
}

local m_mlines = _m.textadept.mlines
keys.am = {
  a  = { m_mlines.add             },
  sa = { m_mlines.add_multiple    },
  r  = { m_mlines.remove          },
  sr = { m_mlines.remove_multiple },
  u  = { m_mlines.update          },
  c  = { m_mlines.clear           },
}

local m_macro = _m.textadept.macros
keys.cam  = { m_macro.toggle_record }
keys.csam = { m_macro.play          }

keys.cr   = { textadept.io.open              }
keys.co   = { 'save', b                      }
keys.cso  = { 'save_as', b                   }
keys.cx   = { 'close', b                     }
keys.csx  = { textadept.io.close_all         }
keys.cz   = { 'undo', b                      }
keys.csz  = { 'redo', b                      }
keys.as.a = { 'select_all', b                }
keys.an   = { 'goto_buffer', v, 1, false     }
keys.ap   = { 'goto_buffer', v, -1, false    }
keys.can  = { textadept.goto_view, 1, false  }
keys.cap  = { textadept.goto_view, -1, false }

local m_handlers = textadept.handlers
keys.cab = { m_handlers.handle, 'call_tip_click', 1 }
keys.caf = { m_handlers.handle, 'call_tip_click', 2 }

keys.cs     = { textadept.find.focus }
keys['c\t'] = { textadept.pm.focus   }
keys.cc     = { textadept.focus_command }

keys.san   = { function() view.size = view.size + 10 end }
keys.sap   = { function() view.size = view.size - 10 end }

local function pm_activate(text)
  textadept.pm.entry_text = text
  textadept.pm.activate()
end

keys.ct    = {} -- Textadept command chain
keys.ct.s  = { 'split',   v, false    } -- horizontal
keys.ct.ss = { 'split',   v           } -- vertical
keys.ct.n  = { textadept.new_buffer   }
keys.ct.b  = { pm_activate, 'buffers' }
keys.ct.c  = { pm_activate, 'ctags'   }
keys.ct.m  = { pm_activate, 'macros'  }
keys.ct.x  = { function() view:unsplit() return true end  }
keys.ct.sx = { function() while view:unsplit() do end end }
keys.ct.f  = { function()
  local buffer = buffer
  buffer:toggle_fold( buffer:line_from_position(buffer.current_pos) )
end }

local function toggle_setting(setting)
  local state = buffer[setting]
  if type(state) == 'boolean' then
    buffer[setting] = not state
  elseif type(state) == 'number' then
    buffer[setting] = buffer[setting] == 0 and 1 or 0
  end
  textadept.handlers.update_ui() -- for updating statusbar
end

keys.ct.v   = {} -- view chain
keys.ct.v.e = { toggle_setting, 'view_eol' }
keys.ct.v.w = { toggle_setting, 'wrap_mode' }
keys.ct.v.i = { toggle_setting, 'indentation_guides' }
keys.ct.v.t = { toggle_setting, 'use_tabs' }
keys.ct.v[' '] = { toggle_setting, 'view_ws' }
keys.ct.v.p = { textadept.pm.toggle_visible }
