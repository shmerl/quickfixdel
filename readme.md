# Quickfix delete

Neovim Lua plugin which provides a keymapping (`dd` by default) for deleting entries in the quickfix list window.

Inspired by [quickfixdd](https://github.com/TamaMcGlinn/quickfixdd) by [@TamaMcGlinn](https://github.com/TamaMcGlinn), but written in Lua adding optional key customization.

## Installation

Default installation with lazy.nvim:

```lua
   'shmerl/quickfixdel'
```

## Optional setup

Installation with lazy.nvim setting a custom key (`F8`):

```lua
   {
      'shmerl/quickfixdel',
      config = function()
         require('quickfixdel'):setup({ key = '<F8>' })
      end
   }
```

You can use any **string** value for key that's acceptable as rhs described in `:help vim.keymap.set`.
