-- lua/invoke_nvim/history.lua
-- Manages task history and favorites

local M = {}

local history_file = vim.fn.stdpath("data") .. "/invoke_nvim_history.json"
local favorites_file = vim.fn.stdpath("data") .. "/invoke_nvim_favorites.json"

-- Load data from file
local function load_json_file(file_path)
  local file = io.open(file_path, "r")
  if not file then return {} end
  
  local content = file:read("*a")
  file:close()
  
  local success, data = pcall(vim.json.decode, content)
  return success and data or {}
end

-- Save data to file
local function save_json_file(file_path, data)
  local file = io.open(file_path, "w")
  if not file then return false end
  
  local content = vim.json.encode(data)
  file:write(content)
  file:close()
  return true
end

-- Get task history
function M.get_history()
  return load_json_file(history_file)
end

-- Add task to history
function M.add_to_history(task_name, args)
  local history = M.get_history()
  local entry = {
    task = task_name,
    args = args or {},
    timestamp = os.time(),
    date = os.date("%Y-%m-%d %H:%M:%S")
  }
  
  -- Remove existing entry if it exists
  for i, item in ipairs(history) do
    if item.task == task_name and vim.deep_equal(item.args, args or {}) then
      table.remove(history, i)
      break
    end
  end
  
  -- Add to beginning
  table.insert(history, 1, entry)
  
  -- Limit history size
  local max_history = require("invoke_nvim").options.max_history or 10
  while #history > max_history do
    table.remove(history)
  end
  
  save_json_file(history_file, history)
end

-- Get favorites
function M.get_favorites()
  return load_json_file(favorites_file)
end

-- Add task to favorites
function M.add_to_favorites(task_name, args)
  local favorites = M.get_favorites()
  local entry = {
    task = task_name,
    args = args or {},
    added_at = os.time(),
    added_date = os.date("%Y-%m-%d %H:%M:%S")
  }
  
  -- Check if already exists
  for _, item in ipairs(favorites) do
    if item.task == task_name and vim.deep_equal(item.args, args or {}) then
      return false -- Already exists
    end
  end
  
  table.insert(favorites, entry)
  save_json_file(favorites_file, favorites)
  return true
end

-- Remove task from favorites
function M.remove_from_favorites(task_name, args)
  local favorites = M.get_favorites()
  for i, item in ipairs(favorites) do
    if item.task == task_name and vim.deep_equal(item.args, args or {}) then
      table.remove(favorites, i)
      save_json_file(favorites_file, favorites)
      return true
    end
  end
  return false
end

-- Check if task is in favorites
function M.is_favorite(task_name, args)
  local favorites = M.get_favorites()
  for _, item in ipairs(favorites) do
    if item.task == task_name and vim.deep_equal(item.args, args or {}) then
      return true
    end
  end
  return false
end

-- Clear history
function M.clear_history()
  save_json_file(history_file, {})
end

-- Clear favorites
function M.clear_favorites()
  save_json_file(favorites_file, {})
end

return M 