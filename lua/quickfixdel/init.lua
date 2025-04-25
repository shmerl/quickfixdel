local QuickfixDel = {
   config = {
      key = "dd", -- defaults to deleting with dd
   },
   autocmd_id = nil,
   setup_calls = 0,
   load_calls = 0
}

function QuickfixDel:new()
   -- polyfill table.unpack for older Lua
   table.unpack = table.unpack or unpack
   self:load()
   return self
end

-- intended to be called for the window that shows quickfix list
local function delete_current_quickfix_entry()
   local qf_list = vim.fn.getqflist()
   local qf_index = 0

   if #qf_list > 0 then
      -- get current cursor line position as qf_index (lines start from 1)
      qf_index, _ = table.unpack(vim.api.nvim_win_get_cursor(0))

      -- remove quickfix element from the array at the index position (Note: table.remove indexes table from 1)
      table.remove(qf_list, qf_index)

      -- recreate quickfix list
      vim.fn.setqflist(qf_list, 'r')
   end

   -- set list position or close if last element was deleted
   if #qf_list > 0 then
      vim.cmd.crewind({ count = qf_index })
      vim.cmd.copen()
   else
      vim.cmd.cclose()
   end
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

-- Assumes a static setting, not something you dynamically change multiple times.
-- Intended to be called only once (optionally), early during plugin loading.
-- Calling it later, like when quickfix window is already opened for example, will be glitchy.
function QuickfixDel:setup(config)
   if self.setup_calls > 0 then
      error("Multiple usage of setup() is not supported!")
   end

   process_config_string(self, config, "key")
   self.setup_calls = self.setup_calls + 1
   self:load()
end

function QuickfixDel:load()
   -- new() on plugin loading will call legit load() once
   -- legit setup() would call legit load() the second time
   -- below conditions indicate invalid usage
   local manual_load_no_setup = (self.setup_calls == 0) and (self.load_calls > 0)
   local manual_load_after_setup = (self.load_calls >= 2)

   if manual_load_no_setup or manual_load_after_setup then
      error("Manual usage of load() is not supported!")
   end

   if self.autocmd_id ~= nil then
      -- subsequent load call, delete existing autocmd first to recreate it
      vim.api.nvim_del_autocmd(self.autocmd_id)
   end

   self.autocmd_id = vim.api.nvim_create_autocmd("FileType", {
      pattern = "qf",
      callback = function(event)
         if self.mapped_key ~= nil then
            -- clear existing mapping
            vim.keymap.del("n", self.mapped_key, { buffer = event.buf })
         end

         vim.keymap.set("n", self.config.key, delete_current_quickfix_entry, { buffer = event.buf })
         self.mapped_key = self.config.key
     end
   })

   self.load_calls = self.load_calls + 1
end

return QuickfixDel:new()
