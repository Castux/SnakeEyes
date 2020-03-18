local js = require "js"

function write(...)
    for _,v in ipairs{...} do
        js.global:write_to_output(tostring(v))
    end
end

function print(...)
    local args = {...}
    for i,v in ipairs(args) do
        write(v)
        if i < #args then
            write "\t"
        end
    end
    write "\n"
end

d = require "dice".new

--[[ Environment setup ]]

do
	local mt =
	{
		__index = function(t,k)

            if math[k] then return math[k] end

			local n = k:match("^d(%d+)$")
			if n then
				return d(tonumber(n))
			end
			return nil
		end
	}

	setmetatable(_ENV, mt)
end
