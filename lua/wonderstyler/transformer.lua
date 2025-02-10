local M = {}

local function group_classes(class_list)
	local groups = {}

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
				local element, modifier = rest:match("^(.-)_(.+)$")
				if element then
					groups[base] = groups[base] or { name = base, elements = {} }
					add_element(groups[base], element, modifier)
				else
					groups[base] = groups[base] or { name = base, elements = {} }
					add_element(groups[base], rest, nil)
				end
			end
		elseif string.find(class, "_") then
			local base, modifier = class:match("^(.-)_(.+)$")
			if base and modifier then
				groups[base] = groups[base] or { name = base, modifiers = {} }
				add_modifier(groups[base], modifier)
			else
				groups[class] = groups[class] or { name = class }
			end
		else
			groups[class] = groups[class] or { name = class }
		end
	end

	return groups
end

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

function M.transform(classes)
	local output_lines = {}

	-- Обработка native-классов: добавляем секцию только если список не пустой
	local native_classes = classes.native or {}
	if #native_classes > 0 then
		table.insert(output_lines, "/* Native CSS */")
		local native_groups = group_classes(native_classes)
		for _, group in pairs(native_groups) do
			local lines = format_group(".", group)
			for _, l in ipairs(lines) do
				table.insert(output_lines, l)
			end
			table.insert(output_lines, "")
		end
	end

	-- Обработка css modules: выводим для каждого модуля, если в нём есть классы
	for mod, class_list in pairs(classes.modules or {}) do
		if #class_list > 0 then
			table.insert(output_lines, "/* Module: " .. mod .. " */")
			local mod_groups = group_classes(class_list)
			for _, group in pairs(mod_groups) do
				local lines = format_group(".", group)
				for _, l in ipairs(lines) do
					table.insert(output_lines, l)
				end
				table.insert(output_lines, "")
			end
		end
	end

	return table.concat(output_lines, "\n")
end

return M
