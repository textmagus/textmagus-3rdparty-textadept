-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Dark editor theme for Textadept.

local c = _SCINTILLA.constants
local buffer = buffer

-- Caret.
buffer.caret_fore = 11184810 -- 0xAA | 0xAA << 8 | 0xAA << 16
buffer.caret_line_visible = true
buffer.caret_line_back = 4473924 -- 0x44 | 0x44 << 8 | 0x44 << 16
buffer:set_x_caret_policy(1, 20) -- CARET_SLOP
buffer:set_y_caret_policy(13, 1) -- CARET_SLOP | CARET_STRICT | CARET_EVEN

-- Selection.
buffer:set_sel_fore(1, 3355443) -- 0x33 | 0x33 << 8 | 0x33 << 16
buffer:set_sel_back(1, 10066329) -- 0x99 | 0x99 << 8 | 0x99 << 16

buffer.margin_width_n[0] = 4 + 3 * -- line number margin
  buffer:text_width(c.STYLE_LINENUMBER, '9')

buffer.margin_width_n[1] = 0 -- marker margin invisible

-- Fold margin.
buffer:set_fold_margin_colour(1, 11184810) -- 0xAA | 0xAA << 8 | 0xAA << 16
buffer:set_fold_margin_hi_colour(1, 11184810) -- 0xAA | 0xAA << 8 | 0xAA << 16
buffer.margin_type_n[2] = c.SC_MARGIN_SYMBOL
buffer.margin_width_n[2] = 10
buffer.margin_mask_n[2] = c.SC_MASK_FOLDERS
buffer.margin_sensitive_n[2] = true

-- Fold margin markers.
buffer:marker_define(c.SC_MARKNUM_FOLDEROPEN, c.SC_MARK_ARROWDOWN)
buffer:marker_set_fore(c.SC_MARKNUM_FOLDEROPEN, 0)
buffer:marker_set_back(c.SC_MARKNUM_FOLDEROPEN, 0)
buffer:marker_define(c.SC_MARKNUM_FOLDER, c.SC_MARK_ARROW)
buffer:marker_set_fore(c.SC_MARKNUM_FOLDER, 0)
buffer:marker_set_back(c.SC_MARKNUM_FOLDER, 0)
buffer:marker_define(c.SC_MARKNUM_FOLDERSUB, c.SC_MARK_EMPTY)
buffer:marker_define(c.SC_MARKNUM_FOLDERTAIL, c.SC_MARK_EMPTY)
buffer:marker_define(c.SC_MARKNUM_FOLDEREND, c.SC_MARK_EMPTY)
buffer:marker_define(c.SC_MARKNUM_FOLDEROPENMID, c.SC_MARK_EMPTY)
buffer:marker_define(c.SC_MARKNUM_FOLDERMIDTAIL, c.SC_MARK_EMPTY)

-- Various.
buffer.call_tip_use_style = 0
buffer:set_fold_flags(16)
buffer.mod_event_mask = c.SC_MOD_CHANGEFOLD
