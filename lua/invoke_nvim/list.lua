-- lua/invoke_nvim/list.lua
-- Parse the output of `invoke --list` to extract available tasks

local M = {}

--- Get a list of available Invoke tasks
-- @return table List of task tables with `name`, `desc`, and optional `aliases`
function M.get_tasks()
  local detector = require("invoke_nvim.detector")
  
  -- Check if we should allow operations
  if not detector.should_allow_operations() then
    return {}
  end
  
  -- Run `invoke --list` and capture output
  local handle = io.popen("invoke --list --no-color 2>/dev/null")
  if not handle then return {} end

  local result = handle:read("*a")
  handle:close()

  local tasks = {}

  -- Parse each line for task name, aliases, and description
  for line in result:gmatch("[^\r\n]+") do
    -- Skip header lines
    if line:match("^Available") then
      goto continue
    end
    
    -- Format with aliases: task_name [alias1, alias2]  Description
    local name, aliases, desc = line:match("^(%S+)%s+%[([%w_,%s]+)%]%s+(.+)$")

    -- Fallback: task_name  Description (no aliases)
    if not name then
      name, desc = line:match("^(%S+)%s+(.+)$")
    end

    -- Insert parsed task into results
    if name and name ~= "" then
      table.insert(tasks, {
        name = name,
        desc = desc or "",
        aliases = aliases and vim.split(aliases:gsub("%s", ""), ",") or {},
      })
    end
    
    ::continue::
  end

  return tasks
end

return M
