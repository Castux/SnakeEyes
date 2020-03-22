print "Dice statistics for Tales from the Loop"

plot(d6, "Trusty old d6")

loop_die = d6:apply(function(x)
	return x == 6 and "success" or "failure"
end)

pushed_die = loop_die:apply(function(x)
	return x == "success" and x or loop_die
end)

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
	numdice[i] = i
	success[i] = (i * loop_die):any("success")(true)
	success_pushed[i] = (i * pushed_die):any("success")(true)
end

plot_raw(numdice, {success, success_pushed})

_6dice = (6 * loop_die):count("success")
plot(_6dice, "Successes on 6 dice")
print(_6dice)
