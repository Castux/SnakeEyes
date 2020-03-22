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

print "Probability of success with multiple dice"

numdice = {}
success = {
	label = "not pushed",
	type = "line"
}
success_pushed = {
	label = "pushed",
	type = "line"
}

for i = 1,10 do
	numdice[i] = i .. (i == 1 and " die" or " dice")
	success[i] = (i * loop_die):any("success")(true)
	success_pushed[i] = (i * pushed_die):any("success")(true)
end

plot_raw(numdice, {success, success_pushed}, false, true)

_6dice = (6 * loop_die):count("success")

print "Example of number of successes (on 6 non-pushed dice)"
print(_6dice)
plot(_6dice, "Successes on 6 dice")
