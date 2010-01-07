-- Copyright 2007-2010 Mitchell Foral mitchell<att>caladbolg.net. See LICENSE.
-- This is a DUMMY FILE used for making LuaDoc for built-in functions in the
-- global view table.

---
-- The currently focused view.
-- It also represents the structure of any view table in 'views'.
module('view')

-- Markdown:
-- ## Fields
--
-- * `doc_pointer`: The pointer to the document associated with this view's
--   buffer. (Used internally; read-only)
-- * `size`: The integer position of the split resizer (if this view is part of
--   a split view).

---
-- Splits the indexed view vertically or horizontally and focuses the new view.
-- @param vertical Flag indicating a vertical split. False for horizontal.
-- @return old view and new view tables.
function view:split(vertical) end

---
-- Unsplits the indexed view if possible.
-- @return boolean if the view was unsplit or not.
function view:unsplit() end

---
-- Goes to the specified buffer in the indexed view.
-- Activates the 'buffer_*_switch' signals.
-- @param n A relative or absolute buffer index.
-- @param absolute Flag indicating if n is an absolute index or not.
function view:goto_buffer(n, absolute) end

---
-- Focuses the indexed view if it hasn't been already.
function view:focus() end

