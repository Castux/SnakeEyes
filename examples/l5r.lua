-- Legend of the Five Rings uses d10s that explode on 10, and dice pools of the
-- type "roll N, keep highest K" and add the results.

-- The basic die we're interested in is expressed simply:

l5r = d10:explode(10, 3)

-- The simple way would be to just use the built in "highest" function:

--plot((5 * l5r):highest(2):sum(), "5 keep 2")

-- Unfortunately, computing "highest" is quite expensive, especially with large dice
-- (these exploding d10s contains forty values), and large "keep" numbers. This method is
-- not practical for dice pools going up to 10 or 15 dice.

-- With some difficulty, we can apply optimizations that allow us to reach higher values
-- within reasonable computing time

-- Start with a die that just counts explosions

countX = (d10 // 10):explode(1, 2)

-- Notice we can turn this into an L5R:

function countToFull(x)
	return 10 * x + d9
end

plot(l5r, "d10 explode on 10", countX:apply(countToFull), "Count explosions then expand")

-- Let's precompute a few

full = {}

for i = 0,5 do
	full[i] = countToFull(i)
end

--[[
We will use the fact that a die that explodes N times will
always be higher than a die that explodes fewer times

So we can first roll these much smaller dice, keep the highest K,
and *then* convert these into full L5R dice.

With the one little issue that if there are identical explosion counts
*under* the K highest, the expanded dice might turn out be bigger than
those already selected:

For instance: 0,0,1,1,3,4 keep 3 would select 1,3,4. But the 1 below could turn out a 17
while the 1 we selected could be only a 13. So we need to roll *all* the ones in this case
to pick the true highest

To summarise:

From a sorted array of "count of explosions", take the `keep` highest,
PLUS every other of the same count as the lowest of the keeps.
Check how many of these lowest overlap with the keep dice.

eg: 0,0,0,0,2,4,4,4 keep 4 yields: 2,4,4,4   (from the single 2, keep 1)
eg: 0,0,2,2,2,2,4,4 keep 4 yields: 2,2,2,2,4,4 (from the four 2's, keep 2)

Then we just convert the high dice into full L5R dice
And we add N keep X of the lowest
]]

function treat(t, keep)

	local lowestIndex = #t - keep + 1
	local lowest = t[lowestIndex]
	local countLowest = 0
	local keepLowest = 0

	for i,v in ipairs(t) do
		if v == lowest then
			countLowest = countLowest + 1

			if i >= lowestIndex then
				keepLowest = keepLowest + 1
			end
		end
	end

	local sum = highestOfSlice(lowest, countLowest, keepLowest)

	for i = lowestIndex, #t do
		if t[i] ~= lowest then
			sum = sum + full[t[i]]
		end
	end

	return sum
end

-- Memoize the commonly repeated operation

function smartHighestSum(collection, keep)

	if keep <= #collection // 2 then
		return collection:highest(keep):sum()
	else
		return collection:drop_lowest(#collection - keep)
	end

end

local memo = {}

function highestOfSlice(explosionCount, numDice, keep)

	if not memo[numDice] then
		memo[numDice] = {}
	end

	local tmp = memo[numDice][keep]

	if not tmp then
		tmp = smartHighestSum(numDice * d9, keep)
		memo[numDice][keep] = tmp
	end

	return tmp + explosionCount * 10
end

function computeL5R(numDice, keep)

	return (numDice * countX):sort():apply(function(t)
		return treat(t,keep)
	end)
end

result = computeL5R(10,8)

plot(result)
print(result)
