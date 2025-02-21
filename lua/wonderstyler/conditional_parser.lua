-- lua/wonderstyler/conditional_parser.lua
local M = {}

-- Helper function to extract module references
local function extract_module_refs(expr)
	local result = {}
	-- Match direct module references (e.g., sList.inner, sNavigationMainLayout.menu)
	for mod, cls in expr:gmatch("([%w_]+)%.([%w_%-]+)") do
		table.insert(result, { module = mod, class = cls })
	end
	return result
end

-- Extract classes from a clsx expression
function M.parse_clsx(expr)
	local result = {
		native = {},
		modules = {},
	}

	-- Handle direct module references first
	local module_refs = extract_module_refs(expr)
	for _, ref in ipairs(module_refs) do
		if not result.modules[ref.module] then
			result.modules[ref.module] = {}
		end
		table.insert(result.modules[ref.module], ref.class)
	end

	-- Handle quoted strings (outside of objects)
	for literal in expr:gmatch("[\"'](.-)[\"']") do
		-- Only process if not inside an object (i.e., not after a colon)
		if not expr:match(":[^,}]*" .. literal:gsub("([%-%.%+])", "%%%1")) then
			for token in literal:gmatch("[%w_%-]+") do
				table.insert(result.native, token)
			end
		end
	end

	-- Handle conditional objects (within curly braces)
	local start = 1
	while true do
		local object_start = expr:find("{", start)
		if not object_start then
			break
		end

		local level = 1
		local i = object_start + 1
		local object_content = ""

		while i <= #expr do
			if expr:sub(i, i) == "{" then
				level = level + 1
			elseif expr:sub(i, i) == "}" then
				level = level - 1
				if level == 0 then
					object_content = expr:sub(object_start + 1, i - 1)
					break
				end
			end
			i = i + 1
		end

		if object_content ~= "" then
			-- Process each key-value pair in the object
			for entry in object_content:gmatch("[^,]+") do
				-- Extract the key part (before the colon)
				local key = entry:match("^%s*%[?([^%]:]+)%]?%s*:")
				if key then
					-- Remove quotes if present
					key = key:gsub("[\"']", "")

					-- Check if it's a module reference
					local mod, cls = key:match("^([%w_]+)%.([%w_%-]+)$")
					if mod and cls then
						if not result.modules[mod] then
							result.modules[mod] = {}
						end
						table.insert(result.modules[mod], cls)
					else
						-- It's a native class
						if key:match("^[%w_%-]+$") then
							table.insert(result.native, key)
						end
					end
				end
			end
		end

		start = i + 1
	end

	return result
end

return M
