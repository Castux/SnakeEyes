dice = {
	d20, "d20",
	(2 * d20):apply(max), "Advantage",
	(2 * d20):apply(min), "Disadvantage"
}

print "Exact outcome"
plot(dice)

print "Lower than or equal to outcome"
plot_cdf(dice)

print "Higher than or equal to outcome"
plot_cdf2(dice)
