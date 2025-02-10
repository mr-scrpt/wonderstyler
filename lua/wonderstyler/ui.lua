-- lua/myplugin/ui.lua
local M = {}

function M.close_popup()
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_close(win, true)
end

--- @param content string — текст для вывода.
function M.show_popup(content)
  -- Создаём новый scratch-буферwon
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = vim.split(content, "\n")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.api.nvim_buf_set_option(buf, "filetype", "scss")

  for _, key in ipairs({ "<esc>", "q" }) do
    vim.api.nvim_buf_set_keymap(
      buf,
      "n",
      key,
      "<cmd>lua require'wonderstyler.ui'.close_popup()<CR>",
      { noremap = true, silent = true }
    )
  end

  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.6)
  local row = math.floor((vim.o.lines - height) / 2 - 1)
  local col = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })
end

return M
