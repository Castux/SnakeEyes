-- Various options for an "advantage" mechanic for d100's

-- The classic advantage: roll two, pick the highest
-- Flipping: roll a d100, and flip the tens and the units if that gives a highest result
-- Upgrading tens: roll a d100, and a d10 on the side. Upgrade the tens to the result of
-- the side die if that gives a highest result (this is equivalent to taking the best of 
-- 2d10 for the tens, and a d10 for the units)

-- As it turns out, these distributions are all very close to each other

base = d100 - 1
ten = d10 - 1

flip = (2 * ten):apply(function(x,y)
	return 10 * max(x,y) + min(x,y)
end)

adv = (2 * base):highest()

bestTen = (2 * ten):highest() * 10 + ten

list = {
	base, "d100",
	flip, "flip",
	adv, "advantage",
	bestTen, "best ten"
}

plot(list)
plot_cdf(list)
