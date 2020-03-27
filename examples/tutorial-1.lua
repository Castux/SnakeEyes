-- In its simplest form, this tool is as a calculator for usual dice expressions. "print" will print out basic information about the dice: probability of each outcome, the "cumulative distributions" (probability of getting results lower or higher than the given one), its average and other statistics.

print "Roll 3 d6's, add them up, and add three to the result"
print(3 * d6 + 3)

print()

print "Roll a d3, a d10, and multiply the results together"
print(d3 * d10)

-- Supported operations are + (addition) - (subtraction) * (multiplication) / (division) // (integer division: rounded down), % (mod, also called remainder), ^ (power or exponentiation). Note the difference between division and integer division.

print()

print "d6 / 2"
print(d6 / 2)

print()

print "d6 // 2"
print(d6 // 2)

-- Multiplication follows a special rule to adhere to the usual way of writing dice rolls: if the left side is a number, it means "roll that many dice and add them together" instead.

print()
print "Roll a d6, multiply the result by 2"
print(d6 * 2)

print()

print "Roll two d6's, and add the results"
print(2 * d6)

-- For a more visual result, you can plot the dice. The second argument to the function plot is the label used in the plot's legend. Note that you can click on the boxes in the legend to hide or show the different curves

plot(2 * d6, "2d6")

-- To compare several dice, you can plot them all at once. You can put a label after each die.

plot(3 * d6, "3d6", 6 * d3, "6d3")
