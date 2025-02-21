local M = {}

-- Функция фильтрации токенов
local function should_ignore_token(token)
	return token == "L" or token == "M" or token == "S"
end

-- Нормализация имени модуля для учёта регистра
local function normalize_module(mod, module_normalization)
	local mod_lower = mod:lower()
	return module_normalization[mod_lower] or mod
end

-- Извлечение сбалансированного блока скобок
local function extract_braced(text, start)
	local level = 0
	local i = start
	local len = #text
	while i <= len do
		local c = text:sub(i, i)
		if c == "{" then
			level = level + 1
		elseif c == "}" then
			level = level - 1
			if level == 0 then
				return text:sub(start, i), i
			end
		end
		i = i + 1
	end
	return nil, i
end

-- Обработка строкового значения
local function process_literal(value, native_order, native_set, modules, module_normalization)
	for token in string.gmatch(value, "[%w_%-]+") do
		if not should_ignore_token(token) then
			local mod, cls = string.match(token, "^([%w_]+)%.([%w_%-]+)$")
			if mod and cls then
				local normalized_mod = normalize_module(mod, module_normalization)
				module_normalization[mod:lower()] = normalized_mod
				modules[normalized_mod] = modules[normalized_mod] or { order = {}, set = {} }
				if not modules[normalized_mod].set[cls] then
					table.insert(modules[normalized_mod].order, cls)
					modules[normalized_mod].set[cls] = true
				end
			else
				if not native_set[token] then
					table.insert(native_order, token)
					native_set[token] = true
				end
			end
		end
	end
end

-- Обработка выражения в скобках
local function process_expr(expr, native_order, native_set, modules, module_normalization)
	for literal in string.gmatch(expr, "[\"'](.-)[\"']") do
		process_literal(literal, native_order, native_set, modules, module_normalization)
	end
	for mod, cls in string.gmatch(expr, "([%w_]+)%.([%w_%-]+)") do
		local normalized_mod = normalize_module(mod, module_normalization)
		module_normalization[mod:lower()] = normalized_mod
		modules[normalized_mod] = modules[normalized_mod] or { order = {}, set = {} }
		if not modules[normalized_mod].set[cls] then
			table.insert(modules[normalized_mod].order, cls)
			modules[normalized_mod].set[cls] = true
		end
	end
end

-- Основная функция парсинга
function M.parse_classes(lines)
	local native_order = {} -- Порядок нативных классов
	local native_set = {} -- Множество для проверки уникальности
	local modules = {} -- Модули с их классами
	local sections_order = {} -- Порядок секций (модули и нативные классы)
	local current_section = nil -- Текущая секция для отслеживания смены

	local content = table.concat(lines, " ")

	local pos = 1
	while true do
		local s, e = content:find("[cC]lass[Nn]ame%s*=%s*", pos)
		if not s then
			s, e = content:find("[cC]lass%s*=%s*", pos)
		end
		if not s then
			break
		end

		local next_char = content:sub(e + 1, e + 1)
		if next_char == '"' or next_char == "'" then
			local quote = next_char
			local closing = content:find(quote, e + 2, true)
			if closing then
				local value = content:sub(e + 2, closing - 1)
				for token in string.gmatch(value, "[%w_%-]+") do
					local mod, class_name = string.match(token, "^([%w_]+)%.([%w_%-]+)$")
					if mod and class_name then
						modules[mod] = modules[mod] or { order = {}, set = {} }
						if not modules[mod].set[class_name] then
							table.insert(modules[mod].order, class_name)
							modules[mod].set[class_name] = true
						end
						if current_section ~= mod then
							table.insert(sections_order, { type = "module", name = mod })
							current_section = mod
						end
					else
						if not native_set[token] then
							table.insert(native_order, token)
							native_set[token] = true
						end
						if current_section ~= "native" then
							table.insert(sections_order, { type = "native" })
							current_section = "native"
						end
					end
				end
				pos = closing + 1
			else
				break
			end
		elseif next_char == "{" then
			-- Обработка выражений вроде { [sList.list_l]: listSize == "L" }
			local value, newpos = extract_braced(content, e + 1) -- Предполагаем функцию extract_braced
			if value then
				local inner = value:sub(2, -2)
				for literal in string.gmatch(inner, "[\"'](.-)[\"']") do
					for token in string.gmatch(literal, "[%w_%-]+") do
						local mod, class_name = string.match(token, "^([%w_]+)%.([%w_%-]+)$")
						if mod and class_name then
							modules[mod] = modules[mod] or { order = {}, set = {} }
							if not modules[mod].set[class_name] then
								table.insert(modules[mod].order, class_name)
								modules[mod].set[class_name] = true
							end
							if current_section ~= mod then
								table.insert(sections_order, { type = "module", name = mod })
								current_section = mod
							end
						else
							if not native_set[token] then
								table.insert(native_order, token)
								native_set[token] = true
							end
							if current_section ~= "native" then
								table.insert(sections_order, { type = "native" })
								current_section = "native"
							end
						end
					end
				end
				pos = newpos + 1
			else
				break
			end
		else
			pos = e + 1
		end
	end

	return {
		native = native_order,
		modules = modules,
		sections_order = sections_order,
	}
end

return M
-- -- lua/myplugin/parser.lua
-- local M = {}
--
-- -- Функция для добавления уникального класса в таблицу-множество
-- local function add_unique(tbl, class)
--   if not tbl[class] then
--     tbl[class] = true
--   end
-- end
--
-- -- Функция фильтрации токенов: если токен равен "L", "M" или "S", он игнорируется
-- local function should_ignore_token(token)
--   return token == "L" or token == "M" or token == "S"
-- end
--
-- -- Если для модуля встречаются варианты разного регистра, выбираем уже известное имя
-- local function normalize_module(mod, modules)
--   for existing, _ in pairs(modules) do
--     if existing:lower() == mod:lower() then
--       return existing
--     end
--   end
--   return mod
-- end
--
-- -- Извлечение сбалансированного блока скобок, начиная с позиции start
-- local function extract_braced(text, start)
--   local level = 0
--   local i = start
--   local len = #text
--   while i <= len do
--     local c = text:sub(i, i)
--     if c == "{" then
--       level = level + 1
--     elseif c == "}" then
--       level = level - 1
--       if level == 0 then
--         return text:sub(start, i), i
--       end
--     end
--     i = i + 1
--   end
--   return nil, i
-- end
--
-- -- Обработка строкового значения (например, внутри кавычек)
-- local function process_literal(value, result)
--   for token in string.gmatch(value, "[%w_%-]+") do
--     if not should_ignore_token(token) then
--       -- Если токен имеет вид module.class, то добавляем в modules
--       local mod, cls = string.match(token, "^([%w_]+)%.([%w_%-]+)$")
--       if mod and cls then
--         mod = normalize_module(mod, result.modules)
--         result.modules[mod] = result.modules[mod] or {}
--         add_unique(result.modules[mod], cls)
--       else
--         add_unique(result.native, token)
--       end
--     end
--   end
-- end
--
-- -- Обработка выражения внутри фигурных скобок (без внешних скобок)
-- local function process_expr(expr, result)
--   -- Сначала ищем строковые литералы, например "list list_top"
--   for literal in string.gmatch(expr, "[\"'](.-)[\"']") do
--     process_literal(literal, result)
--   end
--   -- Затем ищем конструкции вида module.class, например sNavigationMainLayout.menu_top
--   for mod, cls in string.gmatch(expr, "([%w_]+)%.([%w_%-]+)") do
--     mod = normalize_module(mod, result.modules)
--     result.modules[mod] = result.modules[mod] or {}
--     add_unique(result.modules[mod], cls)
--   end
-- end
--
-- --- Основная функция разбора.
-- --- На вход — массив строк (содержимое буфера). На выходе получаем таблицу вида:
-- --- {
-- ---   native = { "header", "page__header", ... },
-- ---   modules = {
-- ---       sNavigationMainLayout = { "root", "inner", "menu", "menu_top", "menu__item", ... },
-- ---       sList = { "list", "inner", "item", "content", "title", ... },
-- ---   }
-- --- }
-- function M.parse_classes(lines)
--   local result = { native = {}, modules = {} }
--   -- Объединяем все строки в одну (убираем переводы строк)
--   local content = table.concat(lines, " ")
--
--   local pos = 1
--   while true do
--     -- Сначала пытаемся найти атрибут className= (для TSX)
--     local s, e = content:find("[cC]lass[Nn]ame%s*=%s*", pos)
--     -- Если не найден, пробуем найти атрибут class= (для HTML)
--     if not s then
--       s, e = content:find("[cC]lass%s*=%s*", pos)
--     end
--     if not s then
--       break
--     end
--
--     local next_char = content:sub(e + 1, e + 1)
--     if next_char == '"' or next_char == "'" then
--       -- Обработка литерального значения в кавычках
--       local quote = next_char
--       local closing = content:find(quote, e + 2, true)
--       if closing then
--         local value = content:sub(e + 1, closing)
--         -- Убираем внешние кавычки
--         value = value:sub(2, -2)
--         process_literal(value, result)
--         pos = closing + 1
--       else
--         break
--       end
--     elseif next_char == "{" then
--       -- Обработка значения в фигурных скобках
--       local value, newpos = extract_braced(content, e + 1)
--       if value then
--         -- Убираем внешние фигурные скобки
--         local inner = value:sub(2, -2)
--         process_expr(inner, result)
--         pos = newpos + 1
--       else
--         break
--       end
--     else
--       pos = e + 1
--     end
--   end
--
--   -- Преобразуем таблицы-множества в массивы
--   local native_list = {}
--   for class, _ in pairs(result.native) do
--     table.insert(native_list, class)
--   end
--   result.native = native_list
--
--   for mod, classes in pairs(result.modules) do
--     local class_list = {}
--     for cls, _ in pairs(classes) do
--       table.insert(class_list, cls)
--     end
--     result.modules[mod] = class_list
--   end
--
--   return result
-- end
--
-- return M
