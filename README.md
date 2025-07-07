# invoke.nvim

A Neovim plugin that brings seamless integration of Python's `invoke` task runner into the modern Neovim development experience.

## 💡 Motivation

Python’s [`invoke`](https://www.pyinvoke.org/) is a powerful, minimalistic task execution tool often used as a replacement for Makefiles, especially in Python-centric projects. It enables you to define project-specific automation like testing, formatting, server startups, and more—entirely in Python.

However, as of the last time I looked, there is:

- **No native Neovim integration** for invoking these tasks interactively
- No Snacks pickers to list and run them
- No convenience mechanism for running `invoke` tasks from within Neovim’s floating terminals

This plugin fills that gap. It’s purpose-built for Python developers who:

- Already use `invoke` as their task runner
- Prefer staying inside Neovim for everything
- Want better integration between their CLI tooling and editor

With `invoke.nvim`, your `invoke` tasks are just a fuzzy search and `<CR>` away using Snacks.

---

## 🚀 Features

- 🔍 Discover tasks via `invoke --list`
- 🧠 Show aliases and descriptions for each task
- 🔭 Launch a Snacks picker with fuzzy filtering
- 💻 Run selected tasks in a floating terminal (via `toggleterm.nvim`)
- 📘 Live preview with task metadata (name, aliases, docstring)
- 🛠️ Configurable keymap and entry point
- 🧠 Simple and reliable: works with any invoke setup
- ⭐ Task history and favorites system
- 🏷️ Task categorization and filtering
- 📝 Interactive argument input with presets
- 🔔 Task execution monitoring and notifications
- 📊 Task statistics and runtime estimation
- 🔗 Integration with overseer.nvim, trouble.nvim, and which-key.nvim

---

## 📦 Installation

### Using Lazy.nvim

This plugin can be loaded conditionally or globally:

```lua
{
  "yourusername/invoke.nvim",
  -- Optional: load only when tasks.py exists
  -- cond = function()
  --   return vim.fn.filereadable(vim.fn.getcwd() .. "/tasks.py") == 1
  -- end,
  config = function()
    require("invoke_nvim").setup()
  end,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "mtoohey31/snacks.nvim",
    "akinsho/toggleterm.nvim",
  },
  cmd = { "InvokeTasks" },
  keys = {
    { "<leader>ti", "<cmd>InvokeTasks<cr>", desc = "Invoke: Open Task Picker" },
  },
}
```

### Using Packer.nvim

```lua
use {
  "yourusername/invoke.nvim",
  config = function()
    require("invoke_nvim").setup()
  end,
  requires = {
    "nvim-lua/plenary.nvim",
    "mtoohey31/snacks.nvim",
    "akinsho/toggleterm.nvim",
  },
}
```

---

## 🧪 Usage

### Open the Picker

- Run `:InvokeTasks`
- Or press `<leader>ti` (default)

### Select a Task

- Scroll through all available tasks from `invoke --list`
- View the aliases and description in a preview window
- Press `<Enter>` to run it in a floating terminal

### Additional Commands

- `:InvokeHistory` - View and rerun recent tasks
- `:InvokeFavorites` - View and run favorite tasks
- `:InvokeByCategory` - Browse tasks by category
- `:InvokeStats` - Show task statistics
- `:InvokeClearHistory` - Clear task history
- `:InvokeClearFavorites` - Clear favorite tasks

### Task Arguments

When selecting a task that accepts arguments, you'll be prompted to enter them interactively. You can also configure argument presets in your setup.

### When No Tasks Are Found

If no invoke tasks are found, the plugin will show a simple warning message. This can happen when:
- No `tasks.py` file exists in the current directory
- The `invoke` command is not installed
- There are no tasks defined in the current project

---

## 🔧 Configuration

```lua
require("invoke_nvim").setup({
  keymap = "<leader>ti", -- Default keymap to open the task picker
  
  -- Task execution settings
  term_direction = "float", -- "float", "horizontal", "vertical"
  close_on_exit = false, -- Keep terminal open after task completes
  show_preview = true, -- Show task preview in picker
  
  -- Task history and favorites
  enable_history = true, -- Track recently run tasks
  max_history = 10, -- Maximum number of recent tasks to remember
  enable_favorites = true, -- Allow marking tasks as favorites
  
  -- Task arguments
  enable_args = true, -- Enable interactive argument input
  arg_presets = {}, -- Predefined argument presets for tasks
  -- Example presets:
  -- arg_presets = {
  --   test = { verbose = true },
  --   build = { clean = true },
  -- },
  
  -- Notifications
  enable_notifications = true, -- Show task completion notifications
  
  -- Integration settings
  overseer_integration = false, -- Integrate with overseer.nvim
  trouble_integration = false, -- Integrate with trouble.nvim
  which_key_integration = false, -- Integrate with which-key.nvim
})
```

---

## 🧱 Requirements

- Python project with `invoke` installed
- A `tasks.py` file (optional - plugin works without it but will show no tasks)

```python
from invoke import task

@task
def test(c):
    c.run("pytest")

@task
def run(c):
    c.run("uvicorn app.main:app --reload")
```

Then run `:InvokeTasks` in Neovim and select from `test`, `run`, etc.

**Note**: The plugin will work in any directory, but will only show tasks if `invoke --list` returns results.

---

## 🔄 Roadmap

- [x] Basic Snacks picker
- [x] Floating terminal runner
- [x] Docstring preview
- [x] Task filtering by tag or group
- [x] Argument prompt support (interactive task args)
- [x] `overseer.nvim` integration
- [x] Task history and favorites
- [x] Task categorization
- [x] Task execution monitoring
- [x] Task statistics and runtime estimation
- [x] Integration with trouble.nvim and which-key.nvim

---

## 🤝 Contributing

Contributions are welcome! PRs and issues are encouraged if you:
- Use `invoke` in your Python workflow
- Want tighter Neovim integration
- Have ideas to improve the UX or performance

---

## 📄 License

MIT License © 2025 Omar Crosby
