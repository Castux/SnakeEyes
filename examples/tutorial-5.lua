-- Now that we can create collections and apply functions to them, it can be tempting to just do that all the time. However, remember that apply enumerates *all* possible combinations of outcomes.

-- For instance, running:
-- print((10 * d10):apply(max))
-- would have to go through 10^10 (ten billion!) combinations, which would take quite a while. Your browser will probably complain that the page has crashed...

-- And yet, the built-in method "highest" goes through them in a breeze:

print "highest of 10d10"
print((10 * d10):highest())

-- Enters the power of the "accumulate" method! Let's get back to the basic sum example. Computing the sum of 10d10 is not an unreasonable question, but we really shouldn't enumerate 10 billions combinations. The key here is that addition can be done *die by die*. Instead of rolling the ten dice, and then adding all the outcomes together, we can very well roll the first die, then the second, then add. Next, we roll the third die and add it to the previous result. Then, we roll the fourth die, add it to the result, and so on.

-- This is exactly what "accumulate" does. You pass it a function that takes only two arguments, and it will combine the first two dice with it, then the result with the third die, then *that* result with the fourth die, and so on until the end.

sum_10d10 = (10 * d10):accumulate(function(x,y)
    return x + y
end)

plot(sum_10d10, "10d10 with accumulate", 10 * d10, "built-in sum")

-- It works! In fact, the built-in sum method is defined exactly like this. Even though sum'ing collections is automatic in most places, the explicit "sum" method exists

plot((2 * d6 .. d4):sum(), "2d6 + d4")

-- "highest", that we saw earlier, is defined exactly as accumulate(max), and "lowest" is accumulate(min). Indeed, you can roll the dice one by one and compare the previous maximum to the new die each time, which is a perfect occasion to use accumulate!

-- Another predefined method is "count", for the common operation of counting how many faces came up with a certain value. It too uses accumulate, so it works fine on a large number of dice!

plot((20 * d6):count(1), "20d6 count 1's")

-- You can also pass a function to "count", which should return true for all the outcomes you want to count

print "Count even faces not divisible by 3 on 5d12"
print((5 * d12):count(function(x)
    return x % 2 == 0 and x % 3 ~= 0
end))

-- Other built-in methods are "all", "any", and "none". They also take either a value, or a function:

print()
print "Snake eyes!"
print((2 * d6):all(1))

-- Here's a final convoluted example: roll a d6, then roll 4 other d6's and check that they're all equal to the result of the first one. In other words, yahtzee!

print()
print "Yahtzee!"
print(d6:apply(function(x)
    return (4*d6):all(x)
end))

-- This last example used "nested" dice. See next tutorial for details!
