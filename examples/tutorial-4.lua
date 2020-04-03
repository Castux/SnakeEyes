-- We've seen how to create dice, and modify them. Now we can move on to *combining* them: that is, rolling two dice at once, and doing something with the results. As a boring example, let's redefine addition:

plot(d6:combine(d8, function(x,y)
    return x + y
end), "d6 + d8")

-- To convince yourself that it truly goes through all combinations, let's combine to return a string composed of both results instead:

print(d6:combine(d8, function(x,y)
    return x .. " and " .. y
end))

-- How about rolling two dice and checking which is bigger?

plot(d6:combine(d6, max), "Max of 2d6")

-- Or rolling two d20 and checking if either is under 15?

plot(d20:combine(d20, function(x,y)
    return x < 15 or y < 15
end), "Any of 2d20 under 15")

-- That is all nice and well, but what about more than 2 dice? Time to talk about "dice collections". To signify rolling several dice together, we need to gather them in a collection. This is done using the ".." operator (normally used for string concatenation in Lua).

collection = d6 .. d10 .. d10

-- If you try to print it, plot it, or use it in any place that expects a die, the program will assume that you want the sum of all dice in the collection:

print "d6 and two d10's in a collection"
plot(collection, "collection")

-- Where it becomes interesting is that collections also have the "apply" method, and it means "roll all dice, and apply that function to the results". As a first example, let's recreate the basic addition.

print "Roll d6 and 2d10, if the d6 is higher than both d10, super success"
print "If it's higher than one d10, success."

print(collection:apply(function(x,y,z)
    if x > y and x > z then
        return "Super success"
    elseif x > y or x > z then
        return "Success"
    else
        return "Failure"
    end
end))

-- It's a good time to come back to the notation "n * die". Earlier we saw that it was an exception. It does not mean "roll the die and multiply by n", but "roll n time the die". We said that it computed the sum. That's not exactly true. What it does is return a collection made of n time the same die. So this works:

plot((3 * d6):apply(function(x,y,z)
    return x + y + z - min(x,y,z)
end), "3d6 keep 2")

-- But since a collection automatically gets sum'ed when it's used instead of a single die, this works too:

plot(3 * d6 + 6, "3d6 + 6")

-- An important thing to remember: apply goes through *all* possible combinations of outcomes. That is the number of faces on each dice multiplied together. For instance, on 3 * d6, it's only 6*6*6 = 316, which is totally within the capacity of modern computers. But 10d10 is already 10 billion possibilities, and 100d20 would take way, way, waaaaay more time than the age of the universe to compute.

-- See next tutorial to see how to go around this... pesky limitation.
