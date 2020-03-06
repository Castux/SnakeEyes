local d
local is_die

local function apply(func, ...)

	local dice = {...}
	local tempk = {}
	local tempp = 1

	-- Replace single values with 1-sided dice

	for i,v in ipairs(dice) do
		if not is_die(v) then
			dice[i] = d{v}
		end
	end

	-- Enumerate all combinations of outcomes

	local outcomes = {}
	local probabilities = {}

	local function rec(level)

		for k,v in pairs(dice[level].data) do
			tempk[level] = k
			tempp = tempp * v

			if level == #dice then
				local res = func(table.unpack(tempk))

				table.insert(outcomes, res)
				table.insert(probabilities, tempp)

			else
				rec(level + 1)
			end

			tempp = tempp / v
		end

	end

	rec(1)
	return d(outcomes, probabilities)
end

local function summary(die)

	local boolean = false
	local outcomes = {}
	for k,_ in pairs(die.data) do
		table.insert(outcomes, k)
		if type(k) == "boolean" then
			boolean = true
		end
	end

	if not boolean then
		table.sort(outcomes)
	end

	local lines = {}
	for _,v in ipairs(outcomes) do
		local line =
		{
			tostring(v),
			die.data[v],
			(not boolean) and die:lte(v)(true) or nil,
			(not boolean) and die:gte(v)(true) or nil,
		}

		table.insert(lines, table.concat(line, "\t"))
	end

	return table.concat(lines, "\n")
end

local function lift(func)
	return function(...)
		return apply(func, ...)
	end
end

local mt =
{
	__call = function(self, arg)
		return self.data[arg] or 0
	end,

	apply = function(self, func)
		return apply(func, self)
	end,

	__add = lift(function(x,y) return x + y end),
	__sub = lift(function(x,y) return x - y end),
	__div = lift(function(x,y) return x / y end),
	__pow = lift(function(x,y) return x ^ y end),
	__idiv = lift(function(x,y) return x // y end),
	__mod = lift(function(x,y) return x % y end),
	__unm = lift(function(x) return -x end),

	lt = lift(function(x,y) return x < y end),
	lte = lift(function(x,y) return x <= y end),
	gt = lift(function(x,y) return x > y end),
	gte = lift(function(x,y) return x >= y end),
	eq = lift(function(x,y) return x == y end),
	neq = lift(function(x,y) return x ~= y end),

	times = function(self, n)
		local t = {}
		for i = 1,n do
			t[i] = self
		end
		return table.unpack(t)
	end,

	__tostring = summary
}

mt.__index = mt

is_die = function(t)
	return getmetatable(t) == mt
end

d = function(outcomes, probabilities)

	if type(outcomes) == "number" then
		local faces = {}
		for i = 1,outcomes do
			faces[i] = i
		end

		return d(faces)
	end

	if not probabilities then
		probabilities = {}
		for i = 1,#outcomes do
			probabilities[i] = 1
		end
	end

	assert(#outcomes == #probabilities)

	local t = {}
	local sum = 0

	for i,v in ipairs(probabilities) do
		sum = sum + v
	end

	local type_found

	local function add_outcome(o,p)
		assert(type(o) == "number" or type(o) == "string" or type(o) == "boolean",
			"only numbers, strings and booleans can be used as outcomes")

		if type_found then
			assert(type(o) == type_found, "all outcomes of a die must be of the same type")
		else
			type_found = type(o)
		end

		t[o] = (t[o] or 0) + p / sum
	end

	for i,v in ipairs(outcomes) do

		if is_die(v) then
			for k,p in pairs(v.data) do
				add_outcome(k, probabilities[i] * p)
			end
		else
			add_outcome(v, probabilities[i])
		end
	end

	return setmetatable({ data = t }, mt)
end

local function accumulate(func, ...)

	local dice = {...}
	local tmp = dice[1]

	for i = 2,#dice do
		tmp = apply(func, tmp, dice[i])
	end

	return tmp
end

local function sum(...)
	return accumulate(function(x,y) return x + y end, ...)
end

mt.__mul = function(a,b)
	if type(a) == "number" then
		return sum(b:times(a))
	else
		return apply(function(x,y) return x * y end, a, b)
	end
end

local function count(func, ...)

	local dice = {...}
	for i,v in ipairs(dice) do
		dice[i] = v:apply(function(x) return func(x) and 1 or 0 end)
	end

	return sum(table.unpack(dice))
end

local function highest(...)
	return accumulate(math.max, ...)
end

local function lowest(...)
	return accumulate(math.min, ...)
end

local function n_lowest(n, ...)

	local helper = function(str,new)

		local current = {new}

		if type(str) == "number" then
			table.insert(current, str)
		else
			for word in str:gmatch("%d+") do
				table.insert(current, tonumber(word))
			end
		end

		local index = 1
		while index < #current and current[index] > current[index + 1] do
			current[index], current[index + 1] = current[index + 1], current[index]
			index = index + 1
		end

		while #current > n do
			table.remove(current)
		end

		return table.concat(current, " ")
	end

	return accumulate(helper, ...)
end

local function nth(n, ...)

	return n_lowest(n, ...):apply(function(str)
		return tonumber(str:match "(%d+)$")
	end)
end

return
{
	d = d,
	apply = apply,
	accumulate = accumulate,
	sum = sum,
	count = count,
	highest = highest,
	lowest = lowest,
	n_lowest = n_lowest,
	nth = nth
}