local js = require "js"
local Die = require "dice"

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

function plot_raw(labels, datasets, stacked)

    assert(type(labels) == "table", "labels should be a table")
    assert(type(datasets) == "table", "datasets should be a table")

    for i,v in ipairs(datasets) do
        assert(type(v) == "table", "datasets should be tables")
    end

    js.global:plot(labels, datasets, stacked)
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

local function plot_multi(dice, labels)

    local outcomes = {}
    local datasets = {}

    for i,die in ipairs(dice) do

        if Die.is_dice_collection(die) then
            die = die:sum()
            dice[i] = die
        end

        local stats = die:compute_stats()
        for _,v in ipairs(stats.outcomes) do
            outcomes[v] = true
        end

        datasets[i] =
        {
            label = labels[i],
            type = "line"
        }
    end

    do
        local type_found
        local tmp = {}
        for k,_ in pairs(outcomes) do
            if not type_found then
                type_found = type(k)
            end
            assert(type_found == type(k), "cannot plot dice of different types")

            table.insert(tmp, k)
        end
        table.sort(tmp)
		outcomes = tmp
    end

    for i,outcome in ipairs(outcomes) do
        for j,die in ipairs(dice) do
            local proba = die(outcome)
            datasets[j][i] = proba ~= 0 and proba or nil
        end
    end

    plot_raw(outcomes, datasets)
end

function plot(...)

    local args = {...}

    if #args == 1 and
        type(args[1]) == "table" and
        not Die.is_die(args[1]) and
        not Die.is_dice_collection(args[1]) then

        args = args[1]
    end

    local dice = {}
    local labels = {}

    local i = 1
    while i <= #args do
        local v = args[i]

        if Die.is_dice_collection(v) then
            v = v:sum()
        end

        if Die.is_die(v) then
            table.insert(dice, v)

            if type(args[i + 1]) == "string" then
                labels[#dice] = args[i + 1]
            end
        end

        i = i + 1
    end

    if #dice == 1 then
        plot_single(dice[1], labels[1])
    else
        plot_multi(dice, labels)
    end
end


--[[ Environment setup ]]

d = Die.new

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
