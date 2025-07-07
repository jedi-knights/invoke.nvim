-- lua/invoke_nvim/snacks.lua
-- Provides a Snacks picker interface for Invoke tasks

local list = require("invoke_nvim.list")
local analyzer = require("invoke_nvim.analyzer")
local history = require("invoke_nvim.history")
local notifications = require("invoke_nvim.notifications")

local M = {}

-- Format task display text with enhanced information
local function format_task_display(task, enhanced)
  local alias_str = #task.aliases > 0 and table.concat(task.aliases, ", ") or ""
  local category_icon = enhanced.category and "[" .. enhanced.category:sub(1,1):upper() .. "] " or ""
  local favorite_icon = enhanced.is_favorite and "★ " or ""
  local running_icon = notifications.is_task_running(task.name) and "▶ " or ""
  
  local display_text = string.format("%s%s%s%-20s │ %-30s │ %s", 
    favorite_icon,
    running_icon,
    category_icon,
    task.name, 
    alias_str, 
    task.desc
  )
  
  return display_text
end

-- Create enhanced preview for task
local function create_task_preview(task, enhanced)
  local preview = {
    "Task: " .. task.name,
    "Category: " .. (enhanced.category or "other"),
    "Aliases: " .. (#task.aliases > 0 and table.concat(task.aliases, ", ") or "None"),
  }
  
  if enhanced.runtime_estimate then
    table.insert(preview, "Est. Runtime: " .. enhanced.runtime_estimate .. "s")
  end
  
  if #enhanced.dependencies > 0 then
    table.insert(preview, "Dependencies: " .. table.concat(enhanced.dependencies, ", "))
  end
  
  if #enhanced.tags > 0 then
    table.insert(preview, "Tags: " .. table.concat(enhanced.tags, ", "))
  end
  
  table.insert(preview, "")
  table.insert(preview, task.desc)
  
  return preview
end

--- Opens the Snacks picker for available Invoke tasks
function M.open()
  local tasks = list.get_tasks()
  if #tasks == 0 then
    vim.notify("No invoke tasks found.", vim.log.levels.WARN)
    return
  end

  -- Enhance tasks with additional information
  local items = {}
  for _, task in ipairs(tasks) do
    local enhanced = analyzer.get_enhanced_task_info(task)
    local display_text = format_task_display(task, enhanced)
    local preview = create_task_preview(task, enhanced)
    
    table.insert(items, {
      text = display_text,
      task = task,
      enhanced = enhanced,
      preview = preview
    })
  end

  -- Create snacks picker
  require("snacks").open({
    title = "Invoke Tasks",
    items = items,
    on_select = function(selected_item)
      if selected_item and selected_item.task then
        require("invoke_nvim.runner").run(selected_item.task.name)
      end
    end,
    preview = function(selected_item)
      if selected_item and selected_item.preview then
        return selected_item.preview
      end
      return {}
    end
  })
end

--- Opens the Snacks picker for task history
function M.open_history()
  local history_entries = history.get_history()
  if #history_entries == 0 then
    vim.notify("No task history found.", vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, entry in ipairs(history_entries) do
    local display_text = string.format("%-20s │ %s │ %s", 
      entry.task,
      entry.date,
      vim.inspect(entry.args)
    )
    
    table.insert(items, {
      text = display_text,
      task_name = entry.task,
      args = entry.args,
      preview = {
        "Task: " .. entry.task,
        "Date: " .. entry.date,
        "Arguments: " .. vim.inspect(entry.args),
        "Runtime: " .. (entry.runtime and entry.runtime .. "s" or "N/A")
      }
    })
  end

  require("snacks").open({
    title = "Invoke Task History",
    items = items,
    on_select = function(selected_item)
      if selected_item then
        require("invoke_nvim.runner").run(selected_item.task_name, selected_item.args)
      end
    end,
    preview = function(selected_item)
      return selected_item and selected_item.preview or {}
    end
  })
end

--- Opens the Snacks picker for favorite tasks
function M.open_favorites()
  local favorites = history.get_favorites()
  if #favorites == 0 then
    vim.notify("No favorite tasks found.", vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, entry in ipairs(favorites) do
    local display_text = string.format("★ %-20s │ %s", 
      entry.task,
      vim.inspect(entry.args)
    )
    
    table.insert(items, {
      text = display_text,
      task_name = entry.task,
      args = entry.args,
      preview = {
        "★ Favorite Task: " .. entry.task,
        "Added: " .. entry.added_date,
        "Arguments: " .. vim.inspect(entry.args)
      }
    })
  end

  require("snacks").open({
    title = "Invoke Favorite Tasks",
    items = items,
    on_select = function(selected_item)
      if selected_item then
        require("invoke_nvim.runner").run(selected_item.task_name, selected_item.args)
      end
    end,
    preview = function(selected_item)
      return selected_item and selected_item.preview or {}
    end
  })
end

--- Opens the Snacks picker for tasks by category
function M.open_by_category()
  local tasks = list.get_tasks()
  if #tasks == 0 then
    vim.notify("No invoke tasks found.", vim.log.levels.WARN)
    return
  end

  local grouped = analyzer.group_tasks_by_category(tasks)
  local items = {}
  
  for category, category_tasks in pairs(grouped) do
    table.insert(items, {
      text = string.format("[%s] %d tasks", category:upper(), #category_tasks),
      category = category,
      tasks = category_tasks,
      preview = {
        "Category: " .. category:upper(),
        "Tasks: " .. #category_tasks,
        "",
        "Tasks in this category:",
        unpack(vim.tbl_map(function(t) return "- " .. t.name end, category_tasks))
      }
    })
  end

  require("snacks").open({
    title = "Invoke Tasks by Category",
    items = items,
    on_select = function(selected_item)
      if selected_item and selected_item.tasks then
        -- Open sub-picker for tasks in this category
        local sub_items = {}
        for _, task in ipairs(selected_item.tasks) do
          local enhanced = analyzer.get_enhanced_task_info(task)
          local display_text = format_task_display(task, enhanced)
          local preview = create_task_preview(task, enhanced)
          
          table.insert(sub_items, {
            text = display_text,
            task = task,
            enhanced = enhanced,
            preview = preview
          })
        end
        
        require("snacks").open({
          title = "Invoke Tasks - " .. selected_item.category:upper(),
          items = sub_items,
          on_select = function(sub_selected_item)
            if sub_selected_item and sub_selected_item.task then
              require("invoke_nvim.runner").run(sub_selected_item.task.name)
            end
          end,
          preview = function(sub_selected_item)
            return sub_selected_item and sub_selected_item.preview or {}
          end
        })
      end
    end,
    preview = function(selected_item)
      return selected_item and selected_item.preview or {}
    end
  })
end

return M 