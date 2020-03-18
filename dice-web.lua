local js = require "js"
local dice = require "dice"

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

local function plot_raw(labels, datasets)

    assert(type(labels) == "table", "labels should be a table")
    assert(type(datasets) == "table", "datasets should be a table")

    for i,v in ipairs(datasets) do
        assert(type(v) == "table", "datasets should be tables")
    end

    js.global:plot(labels, datasets)
end

local function plot_single(die, name)

    local stats = die:compute_stats()
    name = name or ""

    local probas = {}
    for i,v in ipairs(stats.outcomes) do
        probas[i] = die(v)
    end

    probas.label = name .. " (=)"
    probas.type = "bar"
    stats.lte.label = name .. " (<=)"
    stats.lte.type = "line"
    stats.gte.label = name .. " (>=)"
    stats.gte.type = "line"

    plot_raw(stats.outcomes, { probas, stats.lte, stats.gte })
end

function plot(...)

    local args = {...}

    if dice.is_die(args[1]) then
        plot_single(args[1], args[2])
    elseif dice.is_dice_collection(args[1]) then
        plot_single(args[1]:sum(), args[2])
    else
        plot_raw(...)
    end

end


--[[ Environment setup ]]

d = dice.new

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
