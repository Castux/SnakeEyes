-- Resource dice, also called usage dice or cascading dice, are a way to track
-- consumables in a game in a more fuzzy way than simply counting. It can also be
-- used for timers.

-- Each resource is tracked by saying it is currently one from a sequence of dice
-- (for instance d20, d12, d10, d8, d6, d4), the largest meaning there is plenty of it,
-- and the smallest meaning it's about to run out. After using that resource in game, roll
-- the corresponding die. If it's above a certain threshold, no changes. If it's under, the
-- resource is downgraded to the next smaller die, meaning there is now "less" of it.

-- After rolling a under the threshold on the smallest die, the resource runs out.

-- Since each die dX follows a geometric distribution, it has on average X/limit rolls before
-- coming out a one. This means that the average number of rolls for a certain die is the sum
-- of faces/limit for itself and all the smaller ones.

limit = 2		-- rolling this or under downgrades the die

faces = {4,6,8,10,12,20}

function resource(base)
	
	local result = base:apply(function(x)
		return x > limit and 1 or 0
	end)
	
	return result:explode(1, 30) + 1
end

d4r = resource(d4)
dice = {d4r}

for i = 2,#faces do
	dice[i] = resource(d(faces[i])) + dice[i-1]
end

list = {}

print "Number of rolls before running out"

for i,v in ipairs(dice) do
	table.insert(list, v)
	
	local label = "d" .. faces[i]
	table.insert(list, label)
end

plot(list)

print "Probability of getting at least N rolls"

plot_cdf2(list)

print "Averages:"

local sum = 0
for i,v in ipairs(faces) do
	sum = sum + v/limit
	print("d" .. v, sum)
end
