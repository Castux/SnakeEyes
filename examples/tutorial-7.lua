-- So far we saw only the basic plot function. Let's get into details. When you pass it a single die (optionally followed by a label), it will plot it as a bar chart, with the cumulative distributions as lines:

plot(3 * d6, "3d6")

-- You can also pass several dice (and optional labels) to plot, in which case it will only draw the outcomes (as lines, for clarity):

plot(
    3 * d6, "3d6",
    2 * d10, "2d10",
    (5 * d5):count(1), "5d5 count 1's"
)

-- To have the same kind of combined graph but for the cumulative distributions, use plot_cdf and plot_cdf2:

plot_cdf(
    3 * d6, "3d6",
    2 * d10, "2d10",
    (5 * d5):count(1), "5d5 count 1's"
)

plot_cdf2(
    3 * d6, "3d6",
    2 * d10, "2d10",
    (5 * d5):count(1), "5d5 count 1's"
)

-- Repeating all these arguments is not very nice, so you can also put them all in a table and reuse them:

t = {d6, "1d6", 2 * d6, "2d6", 3 * d6, "3d6"}
plot(t)
plot_cdf(t)
plot_cdf2(t)

-- There is another plot function: plot_transposed, which can be useful to compare distributions, especially when they have only a few outcomes. It puts the dice on the X axis, and their outcomes as a stacked bar graph vertically:

plot_transposed(
    (3*d6):lowest(), "lowest of 3d6",
    (6*d6):lowest(), "lowest of 6d6"
)

-- Finally, the library exposes the internal plotting function. See the documentation for the full explanation:
-- https://snake-eyes.io/docs.html#plot_rawlabels-datasets-stacked-percentage

x = {}
y1 = { type = "line", label = "sin" }
y2 = { type = "scatter", label = "cos" }
y3 = { label = "x^2 / 50"}
for i = 1,100 do
	x[i] = i / 10
	y1[i] = sin(x[i])
	y2[i] = cos(x[i])
    y3[i] = x[i]^2 / 50
end

plot_raw(x, {y1, y2, y3})
