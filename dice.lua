local Die = {}
local DiceCollection = {}

local function is_die(d)
	return getmetatable(d) == Die
end

local function is_dice_collection(dc)
	return getmetatable(dc) == DiceCollection
end

--[[ Die ]]

Die.__index = Die

function Die.new(outcomes, probabilities)
	
	if type(outcomes) == "number" then
		local faces = {}
		for i = 1,outcomes do
			faces[i] = i
		end

		outcomes = faces
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
		
		if is_dice_collection(v) then
			v = v:sum()
		end

		if is_die(v) then
			for k,p in pairs(v.data) do
				add_outcome(k, probabilities[i] * p)
			end
		else
			add_outcome(v, probabilities[i])
		end
	end

	return setmetatable({ data = t }, Die)
end

local function fmt(x)
	return string.format("%6.2f%%", x * 100)
end

function Die:summary()

	local boolean = false
	local outcomes = {}
	for k,_ in pairs(self.data) do
		table.insert(outcomes, k)
		if type(k) == "boolean" then
			boolean = true
		end
	end

	local lte, gte = {},{}
	if not boolean then
		table.sort(outcomes)
		
		local sum = 0
		for i = 1,#outcomes do
			sum = sum + self.data[outcomes[i]]
			lte[i] = sum
		end
		
		sum = 0
		for i = #outcomes,1,-1 do
			sum = sum + self.data[outcomes[i]]
			gte[i] = sum
		end
	end

	local lines = {}
	for i,v in ipairs(outcomes) do
		local line =
		{
			tostring(v),
			fmt(self.data[v]),
			(not boolean) and fmt(lte[i]) or nil,
			(not boolean) and fmt(gte[i]) or nil,
		}

		table.insert(lines, table.concat(line, "\t"))
	end

	return table.concat(lines, "\n")
end

function Die:__concat(other)
	return DiceCollection.new{self, other}
end

Die.__tostring = Die.summary

local function lift(func)
	return function(a,b)
		
		if is_dice_collection(a) then
			a = a:sum()
		end
		
		if b and is_dice_collection(b) then
			b = b:sum()
		end
		
		if not is_die(a) then
			a = Die.new{a}
		end
		
		if b and not is_die(b) then
			b = Die.new{b}
		end
		
		return DiceCollection.new{a,b}:apply(func)
	end	
end

Die.__add = lift(function(x,y) return x + y end)
Die.__sub = lift(function(x,y) return x - y end)
Die.__div = lift(function(x,y) return x / y end)
Die.__pow = lift(function(x,y) return x ^ y end)
Die.__idiv = lift(function(x,y) return x // y end)
Die.__mod = lift(function(x,y) return x % y end)
Die.__unm = lift(function(x) return -x end)

Die.lt = lift(function(x,y) return x < y end)
Die.lte = lift(function(x,y) return x <= y end)
Die.gt = lift(function(x,y) return x > y end)
Die.gte = lift(function(x,y) return x >= y end)
Die.eq = lift(function(x,y) return x == y end)
Die.neq = lift(function(x,y) return x ~= y end)

local mul = lift(function(x,y) return x * y end)

function Die.__mul(a,b)
	
	if type(a) == "number" then
		local t = {}
		for i = 1,a do
			t[i] = b
		end
		return DiceCollection.new(t)
	end
	
	return mul(a,b)	
end

function Die:__call(v)
	return self.data[v] or 0
end

function Die:apply(func)
	return DiceCollection.apply({self}, func)
end

--[[ DiceCollection ]]

DiceCollection.__index = DiceCollection

function DiceCollection.new(dice)
	
	local self = {}
	
	for i,v in ipairs(dice) do
		
		if is_dice_collection(v) then
			v = v:sum()
		end
		
		if not is_die(v) then
			v = Die.new{v}
		end
		
		self[i] = v
	end
	
	setmetatable(self, DiceCollection)
	return self
end

function DiceCollection:apply(func)
	
	local dice = self
	local tempk = {}
	local tempp = 1

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
	return Die.new(outcomes, probabilities)
end

DiceCollection.__add = Die.__add
DiceCollection.__sub = Die.__sub
DiceCollection.__div = Die.__div
DiceCollection.__mul = Die.__mul
DiceCollection.__pow = Die.__pow
DiceCollection.__idiv = Die.__idiv
DiceCollection.__mod = Die.__mod
DiceCollection.__unm = Die.__unm

DiceCollection.__lt = Die.__lt
DiceCollection.__lte = Die.__lte
DiceCollection.__gt = Die.__gt
DiceCollection.__gte = Die.__gte
DiceCollection.__eq = Die.__eq
DiceCollection.__neq = Die.__neq

function DiceCollection:__tostring()
	return self:sum():summary()
end

function DiceCollection:accumulate(func)
	
	local tmp = self[1]
	
	for i = 2, #self do
		tmp = DiceCollection.new{tmp, self[i]}:apply(func)
	end
	
	return tmp
end

function DiceCollection:sum()
	return self:accumulate(function(x,y) return x + y end)
end

function DiceCollection:count(func)
	
	local dice = {}
	for i,v in ipairs(self) do
		dice[i] = v:apply(function(x) return func(x) and 1 or 0 end)
	end
	
	return DiceCollection.new(dice):sum()
end

function DiceCollection:any(func)
	return self:count(func):gt(0)
end

function DiceCollection:all(func)
	return self:count(func):eq(#self)
end

function DiceCollection:highest()
	return self:accumulate(math.max)
end

function DiceCollection:lowest()
	return self:accumulate(math.min)
end

return Die