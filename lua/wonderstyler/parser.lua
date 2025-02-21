-- lua/wonderstyler/parser.lua
local conditional_parser = require("wonderstyler.conditional_parser")
local M = {}

-- Функция для добавления уникального класса в таблицу-множество
local function add_unique(tbl, class)
	if not tbl[class] then
		tbl[class] = true
	end
end

-- Если для модуля встречаются варианты разного регистра, выбираем уже известное имя
local function normalize_module(mod, modules)
	for existing, _ in pairs(modules) do
		if existing:lower() == mod:lower() then
			return existing
		end
	end
	return mod
end

-- Извлечение сбалансированного блока скобок, начиная с позиции start
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

-- Обработка строкового значения (например, внутри кавычек)
local function process_literal(value, result)
	for token in string.gmatch(value, "[%w_%-]+") do
		-- Если токен имеет вид module.class, то добавляем в modules
		local mod, cls = string.match(token, "^([%w_]+)%.([%w_%-]+)$")
		if mod and cls then
			mod = normalize_module(mod, result.modules)
			result.modules[mod] = result.modules[mod] or {}
			add_unique(result.modules[mod], cls)
		else
			add_unique(result.native, token)
		end
	end
end

-- Обработка выражения внутри фигурных скобок (без внешних скобок)
local function process_expr(expr, result)
	-- Проверяем, является ли это вызовом clsx
	local is_clsx = expr:match("^%s*clsx%s*%(")
	if is_clsx then
		-- Извлекаем аргументы clsx (всё между скобками после 'clsx')
		local args_start = expr:find("%(")
		local args_end = #expr
		local level = 1
		for i = args_start + 1, #expr do
			if expr:sub(i, i) == "(" then
				level = level + 1
			elseif expr:sub(i, i) == ")" then
				level = level - 1
				if level == 0 then
					args_end = i
					break
				end
			end
		end

		local clsx_args = expr:sub(args_start + 1, args_end - 1)
		local parsed = conditional_parser.parse_clsx(clsx_args)

		-- Добавляем найденные native классы
		for _, class in ipairs(parsed.native) do
			add_unique(result.native, class)
		end

		-- Добавляем найденные module классы
		for mod, classes in pairs(parsed.modules) do
			mod = normalize_module(mod, result.modules)
			result.modules[mod] = result.modules[mod] or {}
			for _, cls in ipairs(classes) do
				add_unique(result.modules[mod], cls)
			end
		end
		return
	end

	-- Обработка обычных строковых литералов
	for literal in string.gmatch(expr, "[\"'](.-)[\"']") do
		process_literal(literal, result)
	end

	-- Обработка module.class конструкций
	for mod, cls in string.gmatch(expr, "([%w_]+)%.([%w_%-]+)") do
		mod = normalize_module(mod, result.modules)
		result.modules[mod] = result.modules[mod] or {}
		add_unique(result.modules[mod], cls)
	end
end

function M.parse_classes(lines)
	local result = { native = {}, modules = {} }
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
				process_literal(value, result)
				pos = closing + 1
			else
				break
			end
		elseif next_char == "{" then
			local value, newpos = extract_braced(content, e + 1)
			if value then
				local inner = value:sub(2, -2)
				process_expr(inner, result)
				pos = newpos + 1
			else
				break
			end
		else
			pos = e + 1
		end
	end

	-- Преобразуем таблицы-множества в массивы
	local native_list = {}
	for class, _ in pairs(result.native) do
		table.insert(native_list, class)
	end
	result.native = native_list

	for mod, classes in pairs(result.modules) do
		local class_list = {}
		for cls, _ in pairs(classes) do
			table.insert(class_list, cls)
		end
		result.modules[mod] = class_list
	end

	return result
end

return M
