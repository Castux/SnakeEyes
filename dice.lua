local Die = {}
local DiceCollection = {}

local function is_die(d)
	return getmetatable(d) == Die
end

local function is_dice_collection(dc)
	return getmetatable(dc) == DiceCollection
end

local function pack_array(arr)
	return string.pack(string.rep("n",#arr), table.unpack(arr))
end

local function unpack_array(str)

	local t = {}
	local i = 1
	while i <= #str do
		local v,nexti = string.unpack("n", str, i)
		t[#t + 1] = math.tointeger(v) or v
		i = nexti
	end
	return t
end

local function array_copy(arr)
	local copy = {}
	for i,v in ipairs(arr) do
		copy[i] = v
	end
	return copy
end

--[[ Die ]]

Die.__index = Die
Die.is_die = is_die
Die.is_dice_collection = is_dice_collection
Die.unpack_array = unpack_array

local function check_type(o)
	local t = type(o)
	if t == "number" or t == "boolean" or t == "string" then
		return true
	end

	if t == "table" then
		for i,v in ipairs(o) do
			if type(v) ~= "number" then
				return false
			end
		end
	end

	return true
end

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

		assert(check_type(o), "outcomes of a die can only be of types: number, boolean, string, or array of numbers")

		if type_found then
			assert(type(o) == type_found, "all outcomes of a die must be of the same type")
		else
			type_found = type(o)
		end

		if type(o) == "table" then
			o = pack_array(o)
		end

		t[o] = (t[o] or 0) + p
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

	for k,v in pairs(t) do
		t[k] = v / sum
	end

	return setmetatable({ data = t, type = type_found }, Die)
end

local function average(die)

	assert(die.type == "number", "Cannot compute average of a non numerical die")

	local sum = 0
	for outcome,proba in pairs(die.data) do
		sum = sum + outcome * proba
	end

	local ave = sum
	local sum = 0
	for outcome,proba in pairs(die.data) do
		sum = sum + proba * (outcome - ave)^2
	end
	local stdev = math.sqrt(sum)

	return ave,stdev
end

local precision = 0.0001

function Die:percentile(x)

	assert(x >= 0 and x <= 1, "Percentile argument should be between 0 and 1")
	local stats = self:compute_stats()

	local candidates = {}
	for i = 1,#stats.outcomes do
		if stats.lte[i] >= x - precision and
			stats.gte[i] >= (1-x) - precision then

			table.insert(candidates, stats.outcomes[i])
			if #candidates == 2 then break end
		end
	end

	if #candidates == 1 then
		return candidates[1]
	else
		return (candidates[1] + candidates[2]) / 2
	end
end

function Die:compute_stats(no_madm)

	if self.stats then
		return self.stats
	end

	local outcomes = {}
	for k,_ in pairs(self.data) do
		table.insert(outcomes, k)
	end

	local probabilities, lte, gte = {},{},{}
	if self.type == "number" then
		table.sort(outcomes)
	end

	local sum = 0
	for i = 1,#outcomes do
		probabilities[i] = self.data[outcomes[i]]
		gte[i] = 1 - sum
		sum = sum + probabilities[i]
		lte[i] = sum

		if i == #outcomes then
			lte[i] = 1
		end
	end

	local ave,stdev
	if self.type == "number" then
		ave,stdev = average(self)
	end

	if self.type == "table" then
		for i,v in ipairs(outcomes) do
			outcomes[i] = unpack_array(v)
		end
	end

	self.stats =
	{
		outcomes = outcomes,
		probabilities = probabilities,
		lte = self.type == "number" and lte or nil,
		gte = self.type == "number" and gte or nil,
		average = ave,
		stdev = stdev
	}

	return self.stats
end

local function fmt(x)
	return string.format("%6.2f%%", x * 100)
end

function Die:summary()

	self:compute_stats()

	local lines = {}

	if self.type == "number" then
		lines[1] = "    \t    =\t   <=\t   >="
	else
		lines[1] = "    \t    ="
	end

	for i,v in ipairs(self.stats.outcomes) do
		local line =
		{
			(type(v) == "table") and table.concat(v, ",") or tostring(v),
			fmt(self.stats.probabilities[i]),
			self.stats.lte and fmt(self.stats.lte[i]) or nil,
			self.stats.gte and fmt(self.stats.gte[i]) or nil,
		}

		table.insert(lines, table.concat(line, "\t"))
	end

	if self.stats.average then
		table.insert(lines, string.format("Average: %.2f, standard deviation: %.2f", self.stats.average, self.stats.stdev))

		local median = self:percentile(0.5)
		local madm = self:apply(function(x)
			return math.abs(x - median)
		end):percentile(0.5)
		table.insert(lines, string.format("Median: %f, MADM: %f", median, madm))
		table.insert(lines, string.format("Quartiles: %f, %f, %f",
			self:percentile(0.25),
			median,
			self:percentile(0.75)))
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
	if type(v) == "table" then
		v = pack_array(v)
	end
	return self.data[v] or 0
end

function Die:apply(func)
	return DiceCollection.apply({self}, func)
end

function Die:explode(cond, rerolls)

	if rerolls == 0 then
		return self
	end

	if type(cond) ~= "function" then
		local value = cond
		cond = function(x)
			return x == value
		end
	end

	local next = self:explode(cond, rerolls - 1)

	return self:apply(function(x)
		if cond(x) then
			return x + next
		else
			return x
		end
	end)
end

function Die:sum()

	return self:apply(function(t)
		if type(t) ~= "table" then
			return t
		end

		local sum = 0
		for i,v in ipairs(t) do
			sum = sum + v
		end
		return sum
	end)
end

--[[ DiceCollection ]]

DiceCollection.__index = DiceCollection

function DiceCollection.new(dice)

	local self = {}

	for i,v in ipairs(dice) do

		if is_dice_collection(v) then
			for _,w in ipairs(v) do
				table.insert(self, w)
			end
		else
			if not is_die(v) then
				v = Die.new{v}
			end

			table.insert(self, v)
		end
	end

	setmetatable(self, DiceCollection)
	return self
end

function DiceCollection:__concat(other)
	return DiceCollection.new{self, other}
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
			tempk[level] = dice[level].type == "table" and unpack_array(k) or k
			tempp = tempp * v

			if level == #dice then
				local args = {}
				for i,v in ipairs(tempk) do
					args[i] = type(v) == "table" and array_copy(v) or v
				end
				local res = func(table.unpack(args))

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

	if type(func) ~= "function" then
		local value = func
		func = function(x) return x == value end
	end

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

function DiceCollection:none(func)
	return self:count(func):eq(0)
end

local function insert_in_sorted_array(arr, v)

	table.insert(arr, v)
	local i = #arr
	while i > 1 and arr[i] < arr[i-1] do
		arr[i], arr[i-1] = arr[i-1], arr[i]
		i = i - 1
	end
end

function DiceCollection:highest(n)

	if not n or n == 1 then
		return self:accumulate(math.max)
	end

	return (d{{}} .. self):accumulate(function(t,v)
		insert_in_sorted_array(t, v)
		if #t > n then
			table.remove(t, 1)
		end
		return t
	end)
end

function DiceCollection:lowest(n)

	if not n or n == 1 then
		return self:accumulate(math.min)
	end

	return (d{{}} .. self):accumulate(function(t,v)
		insert_in_sorted_array(t, v)
		if #t > n then
			table.remove(t)
		end
		return t
	end)
end

return Die
