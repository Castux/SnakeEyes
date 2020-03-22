--[[
With a complete lua interpreter and a plotting function, you can do things
entirely unrelated to dice!
--]]

x = {}
y = { type = "line", label = "sin" }
for i = 1,100 do
	x[i] = i / 10
	y[i] = sin(i / 10)
end

plot_raw(x, {y}, false, false)
