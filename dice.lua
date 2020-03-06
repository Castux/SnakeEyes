local d

local function apply(func, ...)

	local dice = {...}
	local tempk = {}
	local tempp = 1

	-- Replace single numbers with 1-sided dice

	for i,v in ipairs(dice) do
		if type(v) == "number" then
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

	for i,v in ipairs(outcomes) do

		assert(type(v) == "number" or type(v) == "string" or type(v) == "boolean",
			"only numbers, strings and booleans can be used as outcomes")

		if type_found then
			assert(type(v) == type_found, "all outcomes of a die must be of the same type")
		else
			type_found = type(v)
		end

		t[v] = (t[v] or 0) + probabilities[i] / sum
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

return
{
	d = d,
	apply = apply,
	accumulate = accumulate,
	sum = sum,
	count = count
}