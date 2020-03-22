blades = d({"failure", "partial", "success"}, {3,2,1})

print "Blades in the Dark, single roll"

plot(blades, "single die")

multi = {}

for i = 1,8 do
	multi[#multi + 1] = (i * blades):apply(max)
	multi[#multi + 1] = i .. (i == 1 and " die" or " dice")
end

print "Blades in the Dark, multiple dice"

plot_transposed(multi)
