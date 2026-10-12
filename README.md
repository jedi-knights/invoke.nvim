# invoke.nvim

A Neovim plugin that brings seamless integration of Python's `invoke` task runner into the modern Neovim development experience.

## Motivation

Python's [`invoke`](https://www.pyinvoke.org/) is a powerful, minimalistic task execution tool often used as a replacement for Makefiles, especially in Python-centric projects. It enables you to define project-specific automation like testing, formatting, server startups, and more — entirely in Python.

However, there is **no native Neovim integration** for invoking these tasks interactively — no picker to list and run them, no convenience mechanism for running `invoke` tasks from within Neovim's floating terminals.

Without this plugin, running a task means switching to a terminal, typing `invoke --list` to remember what's available, scrolling the output, typing `invoke <name>` with any arguments, and context-switching back to the editor when it finishes. Multiply that by every edit-test cycle.

With `invoke.nvim`, your `invoke` tasks are one keystroke (`<leader>ti`) away: a Snacks fuzzy picker lists every task with its aliases and docstring, `<CR>` runs it in a floating terminal, and task history, favorites, and argument presets eliminate the retype.

---

## Features

- Discover tasks via `invoke --list`
- Show aliases and descriptions for each task
- Launch a Snacks picker with fuzzy filtering
- Run selected tasks in a floating terminal (via `toggleterm.nvim`)
- Live preview with task metadata (name, aliases, docstring)
- Configurable keymap and entry point
- Simple and reliable: works with any invoke setup
- Task history and favorites system
- Task categorization and filtering
- Interactive argument input with presets
- Task execution monitoring and notifications
- Task statistics and runtime estimation
- Integration with overseer.nvim, trouble.nvim, and which-key.nvim

---

## Installation

### Using Lazy.nvim

This plugin can be loaded conditionally or globally:

```lua
{
  "jedi-knights/invoke.nvim",
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

### Using native `vim.pack` (Neovim ≥ 0.12)

`vim.pack.add` does not run `setup()` for you — the follow-up call is
explicit. All three runtime dependencies (`plenary.nvim`, `snacks.nvim`,
`toggleterm.nvim`) need to be added separately before the plugin:

```lua
vim.pack.add({
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/folke/snacks.nvim" },
  { src = "https://github.com/akinsho/toggleterm.nvim" },
  { src = "https://github.com/jedi-knights/invoke.nvim" },
})

require("invoke_nvim").setup()
vim.keymap.set("n", "<leader>ti", "<cmd>InvokeTasks<cr>", { desc = "Invoke: Open Task Picker" })
```

Pin to a tag or branch with `version = "..."`. `vim.pack.add` is idempotent —
it clones on first run and does nothing on subsequent runs. Use
`:lua vim.pack.update()` to pull new commits.

### Using Packer.nvim

```lua
use {
  "jedi-knights/invoke.nvim",
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

## Usage

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
- `:InvokeStatus` - Show environment status
- `:InvokeSetup` - Show setup help

### Task Arguments

When selecting a task that accepts arguments, you'll be prompted to enter them interactively. You can also configure argument presets in your setup.

### When No Tasks Are Found

If no invoke tasks are found, the plugin will show a simple warning message. This can happen when:
- No `tasks.py` file exists in the current directory
- The `invoke` command is not installed
- There are no tasks defined in the current project

---

## Configuration

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

  -- Introspection settings
  enable_introspection = true, -- Use Python introspection for task discovery
  fallback_to_invoke_list = true, -- Fallback to invoke --list if introspection fails
  show_source_info = true, -- Show source file and line number in task details
  analyze_dependencies = true, -- Analyze task dependencies via AST parsing
})
```

---

## Requirements

- Python project with `invoke` installed
- A `tasks.py` file (will be auto-created if missing)

### Smart Detection

The plugin intelligently detects your environment:

- **Invoke not installed**: Shows installation instructions
- **No tasks.py in Python project**: Offers to create a basic template
- **No tasks.py in non-Python project**: Suggests navigating to a Python project
- **Global invoke tasks**: Works with system-wide invoke tasks
- **Mixed environments**: Gracefully handles various setups

### Example tasks.py:


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

## Examples

### 1. Discover and run a task from the picker

Place the cursor in a Python project that already has a `tasks.py`, then press `<leader>ti` (or run `:InvokeTasks`). The Snacks picker opens with every task from `invoke --list`:

```
test     Run pytest with coverage
lint     Run ruff and mypy
serve    Start the dev server on :8000
docs     Build the Sphinx docs
```

Type to fuzzy-filter, use `<C-n>` / `<C-p>` to move, and press `<CR>` to run the selected task in a floating terminal. The task's docstring and aliases appear in the preview pane as you move.

### 2. Run a task with arguments

Given this `tasks.py`:

```python
from invoke import task

@task
def test(c, verbose=False, k=None):
    """Run the test suite. Use -v for verbose, -k to filter."""
    cmd = "pytest"
    if verbose:
        cmd += " -v"
    if k:
        cmd += f" -k {k}"
    c.run(cmd)
```

Select `test` from the picker. With `enable_args = true` (default), you'll be prompted to enter arguments interactively — e.g. `--verbose -k auth` — before the task runs. For tasks you run with the same arguments repeatedly, define a preset:

```lua
require("invoke_nvim").setup({
  arg_presets = {
    test = { verbose = true, k = "unit" },
  },
})
```

### 3. Discover tasks from a Taskfile-style `tasks.py`

The plugin discovers every `@task`-decorated function in `tasks.py` — including grouped, aliased, and docstring'd tasks:

```python
from invoke import task

@task(aliases=["t"], help={"watch": "Re-run on file changes"})
def test(c, watch=False):
    """Run the test suite."""
    c.run("pytest --watch" if watch else "pytest")

@task(aliases=["fmt"])
def format(c):
    """Format with ruff and black."""
    c.run("ruff format .")
    c.run("black .")

@task(pre=[format, test])
def ci(c):
    """Format, test, then build. The full local CI pipeline."""
    c.run("python -m build")
```

Run `:InvokeTasks` and you'll see `test` (alias `t`), `format` (alias `fmt`), and `ci` — each with its docstring in the preview. Press `<leader>ti` → `ci` → `<CR>` and the full pipeline runs in a floating terminal. Use `:InvokeDependencies` to see that `ci` depends on `format` and `test` (resolved via AST introspection).

---

## Roadmap

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

## Development

The plugin is pure Lua with a small Python introspection helper (`lua/invoke_nvim/introspector.lua` shells out to Python's `inspect` module to extract task signatures and dependencies). No build step is required.

To hack on it locally:

1. Clone the repo and point your plugin manager at the local path (lazy.nvim: `dir = "/path/to/invoke.nvim"`).
2. Reload Neovim and run `:checkhealth` to confirm `plenary.nvim`, `snacks.nvim`, and `toggleterm.nvim` are available.
3. Edit a `.lua` file, then `:source %` or restart Neovim to pick up the change.
4. Run `:InvokeStatus` to verify the plugin can see `invoke` and your `tasks.py`.
5. For introspection changes, exercise `test_introspection.py` with `python test_introspection.py` from the repo root.

Pull requests should keep the module layout stable (`init.lua` for setup + commands, `snacks.lua` for pickers, `runner.lua` for execution, `list.lua` + `introspector.lua` for discovery) and add tests under the existing introspection harness when touching discovery logic. See **Contributing** below for scope.

---

## Contributing

Contributions are welcome! PRs and issues are encouraged if you:
- Use `invoke` in your Python workflow
- Want tighter Neovim integration
- Have ideas to improve the UX or performance

---

## License

MIT License © 2025 Omar Crosby
