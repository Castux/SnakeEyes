--[[

In Tales from the Loop, players roll a number of d6s according to their
abilities and skills, and if any turns up a 6, the roll is a success.

Players can decide to "push" a roll for a price, which means rerolling
any die that was not already a 6.

Most challenges require only one success, but occasionally the GM can
set a difficulty of 2 or even 3 required successes.

--]]


print "Single die probabilities"

loop_die = d6:apply(function(x)
	return x == 6 and "success" or "failure"
end)

pushed_die = loop_die:apply(function(x)
	return x == "success" and x or loop_die
end)

plot_transposed(
	loop_die, "Single die",
	pushed_die, "Single die pushed"
)

-- Compute the combined dice first

names = {}
dice = {}
pushed_dice = {}

for i = 1,10 do
	names[i] = i .. (i == 1 and " die" or " dice")
	dice[i] = (i * loop_die):count "success"
	pushed_dice[i]= (i * pushed_die):count "success"
end

print "Probability of success with multiple dice"
print "(depending on number of successes required)"

normal = { label = "normal (1)", type = "line" }
pushed = { label = "pushed (1)", type = "line" }
normal2 = { label = "normal (2)", type = "line" }
pushed2 = { label = "pushed (2)", type = "line" }
normal3 = { label = "normal (3)", type = "line" }
pushed3 = { label = "pushed (3)", type = "line" }

for i = 1,#names do
	normal[i] = dice[i]:gte(1)(true)
	pushed[i] = pushed_dice[i]:gte(1)(true)
	normal2[i] = dice[i]:gte(2)(true)
	pushed2[i] = pushed_dice[i]:gte(2)(true)
	normal3[i] = dice[i]:gte(3)(true)
	pushed3[i] = pushed_dice[i]:gte(3)(true)
end

plot_raw(names, {normal, pushed, normal2, pushed2, normal3, pushed3}, false, true)
