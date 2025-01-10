# `telescope-projects.nvim`

[![Version](https://img.shields.io/github/tag/aanatoly/telescope-projects.nvim.png)](https://github.com/aanatoly/telescope-projects.nvim/releases)
[![Licence](https://img.shields.io/github/license/aanatoly/telescope-projects.nvim.png)](./LICENSE)
[![Neovim](https://img.shields.io/badge/NeoVim-0.10-blue.png?logo=neovim)][neovim]
![Contributions](https://img.shields.io/badge/Contributions-Welcome-brightgreen.png)

[Neovim][neovim] Telescope plugin to switch between projects.

![img1](docs/ts-ext-projects-01.png)

![img2](docs/ts-ext-projects-02.png)

**Features:**

- Finds all project in defined workspaces
- Shows opened project first with tab number
- Show recent projects next, up to (recent_max - opened) entries
- Default action (`<CR>`) is to create dedicated tab if needed and jump to it

## Installation

Installation with `lazy`

```lua
return {
  "aanatoly/telescope-projects.nvim",
  cmd = { "ProjectList" },
  depends = { "nvim-telescope/telescope.nvim" },
  opts = {
    workspaces = {
      conf = "~/.config/nvim",
      lazy = "~/.local/share/nvim/lazy",
      dev = "~/dev",
      work = "~/work",
    },
  },
}
```

## Configuration

The default configuration is

```lua
opts = {
  -- symbol to mark recent projects
  recent_sign = "r",
  -- max number of recent entries
  recent_max = 5,
  -- workpsaces table with (name = "path") pairs
  workspaces = {},
  -- max depth to search for project within workspaces
  maxdepth = 4,
}
```

## Usage

You can bind it to a key

```lua

vim.keymap.set("n", "<leader>pp", ":ProjectList<CR>", { desc = "List Projects" })
```

or run from command line `:ProjectList`

## Credits

Big thanks to these awesome projects for ideas and inspiration:

- [telescope-project][telescope-project] - An extension for telescope.nvim that allows you to switch between projects by [Telescope Team][telescope-team]

[neovim]: https://neovim.io/
[telescope-project]: https://github.com/nvim-telescope/telescope-project.nvim
[telescope-team]: https://github.com/nvim-telescope
