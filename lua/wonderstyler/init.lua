-- lua/wonderstyler/init.lua
local parser = require("wonderstyler.parser")
local transformer = require("wonderstyler.transformer")
local ui = require("wonderstyler.ui")

local M = {}

-- Хранилище для сгенерированных стилей
local generated_styles = nil

--- Функция для генерации стилей
function M.generate_styles()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  -- Парсим все встречающиеся class и className
  local classes = parser.parse_classes(lines)
  -- Преобразуем список классов в нужное структурированное представление
  generated_styles = transformer.transform(classes)
  -- Уведомляем пользователя
  vim.notify("Styles generated successfully", vim.log.levels.INFO)
end

--- Функция для показа сгенерированных стилей
function M.show_styles()
  if generated_styles then
    ui.show_popup(generated_styles)
  else
    vim.notify("No styles generated yet. Run generate_styles first.", vim.log.levels.WARN)
  end
end

--- Функция для настройки плагина
--- @param opts table|nil Опции конфигурации (опционально)
function M.setup(opts)
  opts = opts or {}

  -- Регистрируем команды
  vim.api.nvim_create_user_command("WonderStylerGenerate", M.generate_styles, {})
  vim.api.nvim_create_user_command("WonderStylerShow", M.show_styles, {})

  -- Больше не устанавливаем маппинги здесь, так как они будут определены
  -- в конфигурации Lazy.nvim через параметр keys
end

return M
