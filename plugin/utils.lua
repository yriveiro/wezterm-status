local gsub = string.gsub
local pairs = pairs
local type = type

local M = {}

--- Merges two tables recursively with depth tracking to prevent stack overflow.
--- Handles nested tables and protects against infinite recursion.
---@param t1 table The destination table that will receive the merged values
---@param t2 table The source table whose values will be merged into t1
---@return table The merged table (same reference as t1)
---@see merge Internal helper function that performs the recursive merge
function M.table_merge(t1, t2)
  --- Internal helper function that performs the recursive merge with depth tracking
  ---@param dest table The destination table for the current recursion level
  ---@param src table The source table for the current recursion level
  ---@param depth number Current recursion depth
  ---@return table The merged table at current depth
  local function merge(dest, src, depth)
    -- Prevent stack overflow by limiting recursion depth
    if depth > 100 then
      return dest
    end

    for k, v in pairs(src) do
      if type(v) == 'table' then
        -- If value is a table, create or reuse existing table and merge recursively
        dest[k] = type(dest[k]) == 'table' and dest[k] or {}
        merge(dest[k], v, depth + 1)
      else
        -- For non-table values, simply copy the value
        dest[k] = v
      end
    end
    return dest
  end

  return merge(t1, t2, 0)
end

--- Escapes special pattern characters in a string to be used in string pattern matching.
--- This allows the text to be used literally in functions like string.gsub
---@param text string The text to escape
---@return string The escaped text with all special pattern characters preceded by %
---@return number The amount of operations performed
---@example
--- local escaped = escape_pattern("foo-bar.baz")
--- -- Returns "foo%-bar%.baz"
function M.escape_pattern(text)
  return gsub(text, '([^%w])', '%%%1')
end

return M
