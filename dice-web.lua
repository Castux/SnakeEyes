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

function plot_raw(labels, datasets, stacked, percentage)

    assert(type(labels) == "table", "labels should be a table")
    assert(type(datasets) == "table", "datasets should be a table")

    for i,v in ipairs(datasets) do
        assert(type(v) == "table", "datasets should be tables")
    end

    js.global:plot(labels, datasets, stacked, percentage)
end

local function plot_single(die, name)

    local stats = die:compute_stats()
    name = name or ""

    local datasets = { stats.probabilities }

    stats.probabilities.label = name .. " (=)"
    stats.probabilities.type = "bar"

    if die.type == "number" then
        stats.lte.label = name .. " (<=)"
        stats.lte.type = "line"
        stats.gte.label = name .. " (>=)"
        stats.gte.type = "line"

        table.insert(datasets, stats.lte)
        table.insert(datasets, stats.gte)
    end

    local labels = stats.outcomes
    if die.type == "table" then
        labels = {}
        for i,v in ipairs(stats.outcomes) do
            labels[i] = table.concat(v, ",")
        end
    end

    plot_raw(labels, datasets, false, true)
end

local function transpose_datasets(labels, outcomes, datasets)

    local res = {}

    for i,dataset in ipairs(datasets) do
        for j = 1,#outcomes do
            res[j] = res[j] or { label = tostring(outcomes[j]) }
            res[j][i] = dataset[j]
        end

        if labels[i] == nil then
            labels[i] = ""
        end
    end

    return res
end

local function plot_multi(dice, labels, cdf, transpose)

    local outcomes = {}
    local datasets = {}
    local is_packed = {}

    for i,die in ipairs(dice) do

        if Die.is_dice_collection(die) then
            die = die:sum()
            dice[i] = die
        end

        for k,v in pairs(die.data) do
            outcomes[k] = true
            if die.type == "table" then
                is_packed[k] = true
            end
        end

        datasets[i] =
        {
            label = labels[i] or "",
            type = "line"
        }
    end

    do
        local numerical = true
        local tmp = {}
        for k,_ in pairs(outcomes) do
            if type(k) ~= "number" then
                numerical = false
            end
            table.insert(tmp, is_packed[k] and Die.unpack_array(k) or k)
        end

        if numerical then
            table.sort(tmp)
        elseif cdf then
            error("cannot plot CDF for non numerical dice")
        end

		outcomes = tmp
    end

    for i,outcome in ipairs(outcomes) do
        for j,die in ipairs(dice) do
            local proba =
                cdf == "cdf" and die:lte(outcome)(true) or
                cdf == "cdf2" and die:gte(outcome)(true) or
                die(outcome)
            datasets[j][i] = proba ~= 0 and proba or nil
        end

        if type(outcome) == "table" then
            outcomes[i] = table.concat(outcome, ",")
        end
    end

    if transpose then
        datasets = transpose_datasets(labels, outcomes, datasets)
        plot_raw(labels, datasets, true, true)
    else
        plot_raw(outcomes, datasets, false, true)
    end
end

local function treat_plot_args(...)

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

    return dice, labels
end

function plot(...)

    local dice, labels = treat_plot_args(...)

    if #dice == 1 then
        plot_single(dice[1], labels[1])
    else
        plot_multi(dice, labels)
    end
end

function plot_cdf(...)
    local dice, labels = treat_plot_args(...)
    plot_multi(dice, labels, "cdf")
end

function plot_cdf2(...)
    local dice, labels = treat_plot_args(...)
    plot_multi(dice, labels, "cdf2")
end

function plot_transposed(...)
    local dice, labels = treat_plot_args(...)
    plot_multi(dice, labels, nil, true)
end

function print_dice(...)
    local dice, labels = treat_plot_args(...)
    for i,die in ipairs(dice) do
        if(labels[i]) then print(labels[i]) end
        print(die)
        if i < #dice then
            print()
        end
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
