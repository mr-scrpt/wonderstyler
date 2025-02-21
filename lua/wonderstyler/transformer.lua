local M = {}

-- Группировка классов с сохранением порядка блоков
local function group_classes(class_list)
	local groups = {}
	local blocks_order = {}
	local blocks_set = {}

	local function add_modifier(group, modifier)
		group.modifiers = group.modifiers or {}
		group.modifiers[modifier] = true
	end

	local function add_element(base_group, element, modifier)
		base_group.elements = base_group.elements or {}
		base_group.elements[element] = base_group.elements[element] or { name = element, modifiers = {} }
		if modifier then
			base_group.elements[element].modifiers[modifier] = true
		end
	end

	for _, class in ipairs(class_list) do
		if string.find(class, "__") then
			local base, rest = class:match("^(.-)__(.+)$")
			if base and rest then
				if not blocks_set[base] then
					table.insert(blocks_order, base)
					blocks_set[base] = true
				end
				groups[base] = groups[base] or { name = base, elements = {} }
				local element, modifier = rest:match("^(.-)_(.+)$")
				if element then
					add_element(groups[base], element, modifier)
				else
					add_element(groups[base], rest, nil)
				end
			end
		elseif string.find(class, "_") then
			local base, modifier = class:match("^(.-)_(.+)$")
			if base and modifier then
				if not blocks_set[base] then
					table.insert(blocks_order, base)
					blocks_set[base] = true
				end
				groups[base] = groups[base] or { name = base, modifiers = {} }
				add_modifier(groups[base], modifier)
			else
				if not blocks_set[class] then
					table.insert(blocks_order, class)
					blocks_set[class] = true
				end
				groups[class] = groups[class] or { name = class }
			end
		else
			if not blocks_set[class] then
				table.insert(blocks_order, class)
				blocks_set[class] = true
			end
			groups[class] = groups[class] or { name = class }
		end
	end

	return groups, blocks_order
end

-- Форматирование группы в SCSS
local function format_group(prefix, group, indent)
	indent = indent or "  "
	local lines = {}
	table.insert(lines, prefix .. group.name .. " {")
	local child_lines = {}

	if group.modifiers then
		for modifier, _ in pairs(group.modifiers) do
			table.insert(child_lines, indent .. "&_" .. modifier .. " {}")
		end
	end

	if group.elements then
		for _, element in pairs(group.elements) do
			table.insert(child_lines, indent .. "&__" .. element.name .. " {}")
			if element.modifiers then
				for modifier, _ in pairs(element.modifiers) do
					table.insert(child_lines, indent .. "  &_" .. modifier .. " {}")
				end
			end
		end
	end

	for _, cline in ipairs(child_lines) do
		table.insert(lines, cline)
	end
	table.insert(lines, "}")
	return lines
end

-- Основная функция трансформации
function M.transform(classes)
	local output_lines = {}
	local processed_sections = {} -- Для предотвращения дублирования секций

	for _, section in ipairs(classes.sections_order) do
		if section.type == "native" and not processed_sections["native"] then
			processed_sections["native"] = true
			if #classes.native > 0 then
				table.insert(output_lines, "/* Native CSS */")
				local native_groups, native_order = group_classes(classes.native)
				for _, base in ipairs(native_order) do
					local group = native_groups[base]
					local lines = format_group(".", group)
					for _, l in ipairs(lines) do
						table.insert(output_lines, l)
					end
					table.insert(output_lines, "")
				end
			end
		elseif section.type == "module" and not processed_sections[section.name] then
			processed_sections[section.name] = true
			local mod_classes = classes.modules[section.name]
			if mod_classes and #mod_classes.order > 0 then
				table.insert(output_lines, "/* Module: " .. section.name .. " */")
				local mod_groups, mod_order = group_classes(mod_classes.order)
				for _, base in ipairs(mod_order) do
					local group = mod_groups[base]
					local lines = format_group(".", group)
					for _, l in ipairs(lines) do
						table.insert(output_lines, l)
					end
					table.insert(output_lines, "")
				end
			end
		end
	end

	return table.concat(output_lines, "\n")
end

return M
-- local M = {}
--
-- local function group_classes(class_list)
-- 	local groups = {}
--
-- 	local function add_modifier(group, modifier)
-- 		group.modifiers = group.modifiers or {}
-- 		group.modifiers[modifier] = true
-- 	end
--
-- 	local function add_element(base_group, element, modifier)
-- 		base_group.elements = base_group.elements or {}
-- 		base_group.elements[element] = base_group.elements[element] or { name = element, modifiers = {} }
-- 		if modifier then
-- 			base_group.elements[element].modifiers[modifier] = true
-- 		end
-- 	end
--
-- 	for _, class in ipairs(class_list) do
-- 		if string.find(class, "__") then
-- 			local base, rest = class:match("^(.-)__(.+)$")
-- 			if base and rest then
-- 				local element, modifier = rest:match("^(.-)_(.+)$")
-- 				if element then
-- 					groups[base] = groups[base] or { name = base, elements = {} }
-- 					add_element(groups[base], element, modifier)
-- 				else
-- 					groups[base] = groups[base] or { name = base, elements = {} }
-- 					add_element(groups[base], rest, nil)
-- 				end
-- 			end
-- 		elseif string.find(class, "_") then
-- 			local base, modifier = class:match("^(.-)_(.+)$")
-- 			if base and modifier then
-- 				groups[base] = groups[base] or { name = base, modifiers = {} }
-- 				add_modifier(groups[base], modifier)
-- 			else
-- 				groups[class] = groups[class] or { name = class }
-- 			end
-- 		else
-- 			groups[class] = groups[class] or { name = class }
-- 		end
-- 	end
--
-- 	return groups
-- end
--
-- local function format_group(prefix, group, indent)
-- 	indent = indent or "  "
-- 	local lines = {}
-- 	table.insert(lines, prefix .. group.name .. " {")
-- 	local child_lines = {}
--
-- 	if group.modifiers then
-- 		for modifier, _ in pairs(group.modifiers) do
-- 			table.insert(child_lines, indent .. "&_" .. modifier .. " {}")
-- 		end
-- 	end
--
-- 	if group.elements then
-- 		for _, element in pairs(group.elements) do
-- 			table.insert(child_lines, indent .. "&__" .. element.name .. " {}")
-- 			if element.modifiers then
-- 				for modifier, _ in pairs(element.modifiers) do
-- 					table.insert(child_lines, indent .. "  &_" .. modifier .. " {}")
-- 				end
-- 			end
-- 		end
-- 	end
--
-- 	for _, cline in ipairs(child_lines) do
-- 		table.insert(lines, cline)
-- 	end
-- 	table.insert(lines, "}")
-- 	return lines
-- end
--
-- function M.transform(classes)
-- 	local output_lines = {}
--
-- 	-- Обработка native-классов: добавляем секцию только если список не пустой
-- 	local native_classes = classes.native or {}
-- 	if #native_classes > 0 then
-- 		table.insert(output_lines, "/* Native CSS */")
-- 		local native_groups = group_classes(native_classes)
-- 		for _, group in pairs(native_groups) do
-- 			local lines = format_group(".", group)
-- 			for _, l in ipairs(lines) do
-- 				table.insert(output_lines, l)
-- 			end
-- 			table.insert(output_lines, "")
-- 		end
-- 	end
--
-- 	-- Обработка css modules: выводим для каждого модуля, если в нём есть классы
-- 	for mod, class_list in pairs(classes.modules or {}) do
-- 		if #class_list > 0 then
-- 			table.insert(output_lines, "/* Module: " .. mod .. " */")
-- 			local mod_groups = group_classes(class_list)
-- 			for _, group in pairs(mod_groups) do
-- 				local lines = format_group(".", group)
-- 				for _, l in ipairs(lines) do
-- 					table.insert(output_lines, l)
-- 				end
-- 				table.insert(output_lines, "")
-- 			end
-- 		end
-- 	end
--
-- 	return table.concat(output_lines, "\n")
-- end
--
-- return M
