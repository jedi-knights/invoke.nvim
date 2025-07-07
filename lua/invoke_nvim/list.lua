-- lua/invoke_nvim/list.lua
-- Parse the output of `invoke --list` to extract available tasks

local M = {}

--- Get a list of available Invoke tasks
-- @return table List of task tables with `name`, `desc`, and optional `aliases`
function M.get_tasks()
  -- Run `invoke --list` and capture output
  local handle = io.popen("invoke --list --no-color")
  if not handle then return {} end

  local result = handle:read("*a")
  handle:close()

  local tasks = {}

  -- Parse each line for task name, aliases, and description
  for line in result:gmatch("[^\r\n]+") do
    -- Format with aliases: task_name [alias1, alias2]  Description
    local name, aliases, desc = line:match("^(%S+)%s+%[([%w_,%s]+)%]%s+(.+)$")

    -- Fallback: task_name  Description (no aliases)
    if not name then
      name, desc = line:match("^(%S+)%s+(.+)$")
    end

    -- Insert parsed task into results
    if name then
      table.insert(tasks, {
        name = name,
        desc = desc or "",
        aliases = aliases and vim.split(aliases:gsub("%s", ""), ",") or {},
      })
    end
  end

  return tasks
end

return M
