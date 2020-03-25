-- We've seen how to create dice, and modify them. Now we can move on to *combining* them: that is, rolling multiple dice at once, and doing something with the results.

-- To begin, we need to talk about "dice collections". To signify rolling several dice together, we need to gather them in a collection. This is done using the ".." operator (normally used for string concatenation in Lua).

collection = d6 .. d10

-- If you try to print it, plot it, or use it in any place that expects a die, the program will assume that you want the sum of all dice in the collection:

print "d6 and d10 in a collection"
plot(collection, "collection")

-- Where it becomes interesting is that collections also have the "apply" method, and it means "roll all dice, and apply that function to the results". As a first example, let's recreate the basic addition.

plot(collection:apply(function(x,y)
    return x + y
end), "d6 + d10")

-- In detail, this is what happens. The program enumerates all the possible outcomes for a d6 and a d10 rolled at the same time, and computes the probability of combination of outcomes. Then, it calls the function, passing it the outcomes (in the same order as the dice were added to the collection), and creates a new die with the results. This is pretty much how all the built-in operations are defined internally: using apply and simple functions on the individual outcomes.

-- You can put any number of dice in a collection, and the function passed to apply should take as many arguments.

print "d6 - d3 * 2 >= d10"
print((d6 .. d3 .. d10):apply(function(x,y,z)
    return x - 2*y >= z
end))

-- Of course, this was a basic example doable with the built-in methods:

print ""
print((d6 - d3 * 2):gte(d10))
