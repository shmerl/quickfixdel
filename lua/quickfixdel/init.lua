local QuickfixDel = {
   config = {
      key = "dd", -- defaults to deleting with dd
   },
   autocmd_id = nil,
   mapped_key = nil,
   setup_calls = 0
}

-- intended to be called for the window that shows quickfix list
-- deletes entry in the line under the cursor
local function delete_quickfix_entry()
   local quickfix_list = vim.fn.getqflist()
   local quickfix_index = 0

   if #quickfix_list > 0 then
      -- get current cursor line position as quickfix_index (lines start from 1)
      quickfix_index, _ = table.unpack(vim.api.nvim_win_get_cursor(0))

      -- remove quickfix element from the array at the index position (Note: table.remove indexes table from 1)
      table.remove(quickfix_list, quickfix_index)

      -- recreate quickfix list
      vim.fn.setqflist(quickfix_list, 'r')
   end

   -- set list position or close if last element was deleted
   if #quickfix_list > 0 then
      vim.cmd.crewind({ count = quickfix_index })
      vim.cmd.copen()
   else
      vim.cmd.cclose()
   end
end

-- should not be called more than twice
-- which doesn't have access to module scope
local function apply_config(self)
   if self.autocmd_id ~= nil then
      -- subsequent call from setup(), delete existing autocmd first to recreate it below
      vim.api.nvim_del_autocmd(self.autocmd_id)
   end

   self.autocmd_id = vim.api.nvim_create_autocmd("FileType", {
      pattern = "qf",
      desc = "Set up quickfixdel keymap",
      callback = function(event)
         if self.mapped_key ~= nil then
            -- clear existing mapping
            vim.keymap.del("n", self.mapped_key, { buffer = event.buf })
         end

         vim.keymap.set("n", self.config.key, delete_quickfix_entry, { buffer = event.buf, desc = "Delete quickfix entry" })
         self.mapped_key = self.config.key
      end
   })
end

local function process_config_string(self, config, entry)
   -- not setting if config entry name is not provided
   if config[entry] == nil then
      return
   end

   if type(config[entry]) ~= "string" then
      error(string.format("Invlaid type %s used in setup for config.%s! Expected type: string", type(config[entry]), entry))
   end

   self.config[entry] = config[entry]
end

-- Performs a one time setup, not something you dynamically change multiple times.
-- Intended to be called early, during plugin loading.
-- Calling it later, like when quickfix window is already opened for example, will be glitchy.
function QuickfixDel:setup(config)
   if self.setup_calls > 0 then
      error("Multiple usage of setup() is not supported!")
   end

   process_config_string(self, config, "key")
   self.setup_calls = self.setup_calls + 1
   apply_config(self)
end

local function init(self)
   -- polyfill of table.unpack for older Lua
   table.unpack = table.unpack or unpack
   apply_config(self)
   return self
end

return init(QuickfixDel)
