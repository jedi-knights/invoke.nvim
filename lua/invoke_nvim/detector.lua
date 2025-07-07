-- lua/invoke_nvim/detector.lua
-- Handles detection of invoke environment and provides helpful guidance

local M = {}

-- Check if invoke command is available
function M.is_invoke_available()
  local handle = io.popen("which invoke 2>/dev/null")
  if not handle then return false end
  
  local result = handle:read("*a")
  handle:close()
  
  return result and result:match("invoke") ~= nil
end

-- Check if tasks.py exists in current directory
function M.is_tasks_file_present()
  local tasks_file = vim.fn.getcwd() .. "/tasks.py"
  return vim.fn.filereadable(tasks_file) == 1
end

-- Check if we're in a Python project (has pyproject.toml, setup.py, etc.)
function M.is_python_project()
  local python_files = {
    "pyproject.toml",
    "setup.py", 
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    "poetry.lock"
  }
  
  for _, file in ipairs(python_files) do
    if vim.fn.filereadable(vim.fn.getcwd() .. "/" .. file) == 1 then
      return true
    end
  end
  
  return false
end

-- Get invoke version
function M.get_invoke_version()
  local handle = io.popen("invoke --version 2>/dev/null")
  if not handle then return nil end
  
  local result = handle:read("*a")
  handle:close()
  
  return result and result:gsub("%s+", "") or nil
end

-- Check if there are any global invoke tasks
function M.has_global_tasks()
  local handle = io.popen("invoke --list --no-color 2>/dev/null")
  if not handle then return false end
  
  local result = handle:read("*a")
  handle:close()
  
  -- Check if there are any non-empty lines with task names
  for line in result:gmatch("[^\r\n]+") do
    if line:match("^%S+") and not line:match("^Available") then
      return true
    end
  end
  
  return false
end

-- Get environment status
function M.get_environment_status()
  local status = {
    invoke_available = M.is_invoke_available(),
    tasks_file_present = M.is_tasks_file_present(),
    python_project = M.is_python_project(),
    invoke_version = M.get_invoke_version(),
    has_global_tasks = M.has_global_tasks()
  }
  
  return status
end

-- Show helpful setup message
function M.show_setup_help()
  local status = M.get_environment_status()
  
  if not status.invoke_available then
    vim.notify(
      "Invoke is not installed. Install it with: pip install invoke",
      vim.log.levels.ERROR,
      { title = "Invoke.nvim Setup" }
    )
    return false
  end
  
  if not status.tasks_file_present then
    local message = "No tasks.py file found in current directory."
    
    if status.python_project then
      message = message .. "\n\nCreate a tasks.py file to get started:"
      message = message .. "\n\nfrom invoke import task"
      message = message .. "\n\n@task"
      message = message .. "\ndef hello(c):"
      message = message .. "\n    print('Hello, world!')"
      
      -- Offer to create the file
      local choice = vim.fn.confirm(
        "Would you like to create a basic tasks.py file?",
        "&Yes\n&No",
        2
      )
      
      if choice == 1 then
        M.create_basic_tasks_file()
        return true
      end
    else
      message = message .. "\n\nThis doesn't appear to be a Python project."
      message = message .. "\nNavigate to a Python project directory to use invoke.nvim."
    end
    
    vim.notify(message, vim.log.levels.WARN, { title = "Invoke.nvim Setup" })
    return false
  end
  
  return true
end

-- Create a basic tasks.py file
function M.create_basic_tasks_file()
  local tasks_content = [[from invoke import task

@task
def hello(c):
    """Say hello to the world."""
    print("Hello, world!")

@task
def test(c):
    """Run tests."""
    c.run("python -m pytest")

@task
def build(c):
    """Build the project."""
    c.run("python setup.py build")

@task
def clean(c):
    """Clean build artifacts."""
    c.run("rm -rf build/ dist/ *.egg-info/")
]]

  local tasks_file = vim.fn.getcwd() .. "/tasks.py"
  local file = io.open(tasks_file, "w")
  
  if file then
    file:write(tasks_content)
    file:close()
    
    vim.notify(
      "Created basic tasks.py file with example tasks!",
      vim.log.levels.INFO,
      { title = "Invoke.nvim Setup" }
    )
    
    return true
  else
    vim.notify(
      "Failed to create tasks.py file. Check permissions.",
      vim.log.levels.ERROR,
      { title = "Invoke.nvim Setup" }
    )
    return false
  end
end

-- Check if we should allow operations
function M.should_allow_operations()
  local status = M.get_environment_status()
  
  -- Always allow if invoke is available and tasks.py exists
  if status.invoke_available and status.tasks_file_present then
    return true
  end
  
  -- Allow if invoke is available and we have global tasks
  if status.invoke_available and status.has_global_tasks then
    return true
  end
  
  return false
end

-- Get appropriate error message
function M.get_error_message()
  local status = M.get_environment_status()
  
  if not status.invoke_available then
    return "Invoke is not installed. Install with: pip install invoke"
  end
  
  if not status.tasks_file_present then
    if status.python_project then
      return "No tasks.py file found. Create one to get started with invoke tasks."
    else
      return "No tasks.py file found and this doesn't appear to be a Python project."
    end
  end
  
  return "No invoke tasks found."
end

return M 