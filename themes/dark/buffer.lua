-- Copyright 2007-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Dark editor theme for Textadept.

local buffer = buffer

-- Folding.
buffer.property['fold'] = '1'
buffer.property['fold.by.indentation'] = '1'

-- Tabs and indentation.
buffer.tab_width = 2
buffer.use_tabs = false
buffer.indent = 2
buffer.tab_indents = true
buffer.back_space_un_indents = true
buffer.indentation_guides = 1

-- Various.
buffer.auto_c_choose_single = true
buffer.additional_selection_typing = true
