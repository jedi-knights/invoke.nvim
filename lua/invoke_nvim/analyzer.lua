-- lua/invoke_nvim/analyzer.lua
-- Provides enhanced task information and categorization

local M = {}

-- Task categories based on common patterns
local task_categories = {
  test = { "test", "pytest", "unit", "integration", "spec", "check" },
  build = { "build", "compile", "dist", "package", "wheel", "sdist" },
  deploy = { "deploy", "release", "publish", "upload", "ship" },
  dev = { "dev", "serve", "run", "start", "watch", "live" },
  clean = { "clean", "remove", "delete", "purge" },
  format = { "format", "fmt", "style", "lint", "black", "isort" },
  docs = { "docs", "documentation", "readme", "api" },
  db = { "db", "database", "migrate", "seed", "reset" },
  docker = { "docker", "container", "image", "compose" },
  ci = { "ci", "travis", "github", "gitlab", "jenkins" }
}

-- Categorize a task based on its name and description
function M.categorize_task(task)
  local name_lower = string.lower(task.name)
  local desc_lower = string.lower(task.desc or "")
  
  for category, keywords in pairs(task_categories) do
    for _, keyword in ipairs(keywords) do
      if name_lower:find(keyword) or desc_lower:find(keyword) then
        return category
      end
    end
  end
  
  return "other"
end

-- Get task source code (if available)
function M.get_task_source(task_name)
  local tasks_file = vim.fn.getcwd() .. "/tasks.py"
  local file = io.open(tasks_file, "r")
  if not file then return nil end
  
  local content = file:read("*a")
  file:close()
  
  -- Simple regex to find task definition
  local pattern = string.format("@task[^@]*def %s[^@]*", task_name)
  local match = content:match(pattern)
  
  if match then
    -- Clean up the match
    match = match:gsub("^%s+", ""):gsub("%s+$", "")
    return match
  end
  
  return nil
end

-- Estimate task runtime based on historical data
function M.estimate_runtime(task_name)
  local history = require("invoke_nvim.history").get_history()
  local runtimes = {}
  
  for _, entry in ipairs(history) do
    if entry.task == task_name and entry.runtime then
      table.insert(runtimes, entry.runtime)
    end
  end
  
  if #runtimes == 0 then
    return nil
  end
  
  -- Calculate average runtime
  local total = 0
  for _, runtime in ipairs(runtimes) do
    total = total + runtime
  end
  
  return math.floor(total / #runtimes)
end

-- Get task dependencies (basic implementation)
function M.get_task_dependencies(task_name)
  local source = M.get_task_source(task_name)
  if not source then return {} end
  
  local deps = {}
  
  -- Look for @task dependencies
  for dep in source:gmatch("@task%([^)]*depends%[([^%]]+)%]") do
    table.insert(deps, dep)
  end
  
  -- Look for c.run("invoke task") patterns
  for dep in source:gmatch('c%.run%("invoke ([^"]+)"') do
    table.insert(deps, dep)
  end
  
  return deps
end

-- Get task tags/labels
function M.get_task_tags(task_name)
  local source = M.get_task_source(task_name)
  if not source then return {} end
  
  local tags = {}
  
  -- Look for @task tags
  for tag in source:gmatch("@task%([^)]*tags%[([^%]]+)%]") do
    table.insert(tags, tag)
  end
  
  return tags
end

-- Enhanced task information
function M.get_enhanced_task_info(task)
  local enhanced = vim.deepcopy(task)
  
  enhanced.category = M.categorize_task(task)
  enhanced.source = M.get_task_source(task.name)
  enhanced.runtime_estimate = M.estimate_runtime(task.name)
  enhanced.dependencies = M.get_task_dependencies(task.name)
  enhanced.tags = M.get_task_tags(task.name)
  enhanced.is_favorite = require("invoke_nvim.history").is_favorite(task.name)
  
  return enhanced
end

-- Group tasks by category
function M.group_tasks_by_category(tasks)
  local grouped = {}
  
  for _, task in ipairs(tasks) do
    local category = M.categorize_task(task)
    if not grouped[category] then
      grouped[category] = {}
    end
    table.insert(grouped[category], task)
  end
  
  return grouped
end

-- Get task statistics
function M.get_task_stats(tasks)
  local stats = {
    total = #tasks,
    by_category = {},
    with_args = 0,
    favorites = 0
  }
  
  for _, task in ipairs(tasks) do
    local category = M.categorize_task(task)
    stats.by_category[category] = (stats.by_category[category] or 0) + 1
    
    if require("invoke_nvim.history").is_favorite(task.name) then
      stats.favorites = stats.favorites + 1
    end
  end
  
  return stats
end

return M 