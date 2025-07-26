# Invoke.nvim Introspection Features

The `invoke.nvim` plugin now includes advanced Python introspection capabilities for discovering and analyzing Invoke tasks. This feature provides deeper insights into your tasks than the traditional `invoke --list` approach.

## Features

### 1. Task Discovery via Introspection

Instead of relying solely on `invoke --list`, the plugin can now use Python's introspection capabilities to discover tasks directly from your `tasks.py` file. This provides:

- **More detailed information**: Function signatures, docstrings, source locations
- **Better reliability**: Works even if invoke CLI has issues
- **Faster discovery**: No need to execute external commands
- **Source code access**: Can extract and display task source code

### 2. Task Dependency Analysis

The plugin can analyze task dependencies by parsing the Abstract Syntax Tree (AST) of your `tasks.py` file, identifying:

- Tasks that call other tasks via `c.run()`
- Command dependencies within tasks
- Task relationships and call chains

### 3. Enhanced Task Details

Get comprehensive information about any task including:

- Full function signature with parameters
- Complete docstring
- Source file and line number
- Extracted source code
- Parameter types and defaults

## Configuration

Add these options to your plugin configuration:

```lua
require('invoke_nvim').setup({
  -- Introspection settings
  enable_introspection = true,           -- Use Python introspection (default: true)
  fallback_to_invoke_list = true,        -- Fallback to invoke --list if introspection fails
  show_source_info = true,               -- Show source file and line number in task details
  analyze_dependencies = true,           -- Analyze task dependencies via AST parsing
})
```

## User Commands

### `InvokeIntrospect`

Shows all tasks discovered via Python introspection:

```
:InvokeIntrospect
```

This command will display:
- Task names
- Descriptions (from docstrings)
- Function signatures
- Source file information

### `InvokeTaskDetails <task_name>`

Get detailed information about a specific task:

```
:InvokeTaskDetails hello
```

Shows:
- Full task description
- Function signature with parameters
- Source file and line number
- Complete source code

### `InvokeDependencies`

Analyze and display task dependencies:

```
:InvokeDependencies
```

Shows which tasks call other commands or tasks via `c.run()`.

## How It Works

### Task Discovery

The introspection system works by:

1. **Loading the tasks module**: Uses Python's `importlib` to load your `tasks.py` file as a module
2. **Inspecting functions**: Uses `inspect.getmembers()` to find all callable objects
3. **Detecting decorators**: Identifies functions decorated with `@task`
4. **Extracting metadata**: Gathers docstrings, signatures, and source locations

### Dependency Analysis

The dependency analyzer:

1. **Parses the AST**: Uses Python's `ast` module to parse your `tasks.py` file
2. **Finds function calls**: Identifies `c.run()` calls within task functions
3. **Maps relationships**: Creates a dependency graph of task relationships

### Source Code Extraction

When requesting task details, the system:

1. **Locates the function**: Uses line number information from introspection
2. **Reads the source file**: Extracts the relevant lines from your `tasks.py`
3. **Identifies function boundaries**: Uses indentation to determine function scope
4. **Returns formatted code**: Provides the complete function source

## Example Output

### Task Discovery
```
Tasks discovered via introspection:

• hello (c, name='World') - Say hello to someone.
• test (c, verbose=False) - Run the test suite.
• build (c, clean=False) - Build the project.
• install (c, dev=False) - Install the package.
```

### Task Details
```
Task Details for 'hello':

Description: Say hello to someone.
Signature: (c, name='World')
Source: /path/to/tasks.py:12

Source Code:
@task
def hello(c, name="World"):
    """Say hello to someone."""
    print(f"Hello, {name}!")
```

### Dependencies
```
Task Dependencies:

• build:
  - rm -rf build/ dist/ *.egg-info/
  - python setup.py build

• deploy:
  - echo 'Deploying to production...'
  - kubectl apply -f k8s/production/
```

## Benefits Over Traditional Method

| Feature | Traditional `invoke --list` | Introspection |
|---------|---------------------------|---------------|
| Task names | ✅ | ✅ |
| Descriptions | ✅ | ✅ |
| Function signatures | ❌ | ✅ |
| Source locations | ❌ | ✅ |
| Source code | ❌ | ✅ |
| Dependencies | ❌ | ✅ |
| Parameter details | ❌ | ✅ |
| Reliability | ⚠️ (depends on invoke CLI) | ✅ |
| Speed | ⚠️ (external process) | ✅ |

## Troubleshooting

### No Tasks Found

If introspection doesn't find any tasks:

1. **Check file structure**: Ensure `tasks.py` is in the current directory
2. **Verify decorators**: Make sure tasks are decorated with `@task`
3. **Check Python syntax**: Ensure `tasks.py` has valid Python syntax
4. **Fallback mode**: The plugin will automatically fall back to `invoke --list`

### Python Import Errors

If you see Python import errors:

1. **Check dependencies**: Ensure all imports in `tasks.py` are available
2. **Virtual environment**: Make sure you're in the correct Python environment
3. **Path issues**: Verify Python can find your project modules

### Performance Considerations

- Introspection is generally faster than `invoke --list` for small to medium projects
- For very large `tasks.py` files, the initial parsing might take a moment
- Results are cached during the Neovim session for better performance

## Advanced Usage

### Custom Task Discovery

You can extend the introspection system by modifying the Python script in `introspector.lua`. The script is designed to be easily customizable for specific project needs.

### Integration with Other Tools

The introspection data can be integrated with:

- **LSP servers**: Provide task information to language servers
- **Debuggers**: Show task source locations in debugging sessions
- **Documentation generators**: Auto-generate task documentation
- **CI/CD systems**: Validate task configurations

## Future Enhancements

Planned improvements include:

- **Type annotation analysis**: Extract and display type hints
- **Task complexity metrics**: Analyze cyclomatic complexity
- **Test coverage mapping**: Link tasks to their test files
- **Performance profiling**: Track task execution times
- **Dependency visualization**: Generate dependency graphs 