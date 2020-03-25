-- Before we start modifying dice, let's remember that in Lua you can save values in variables. This can be useful to store a die you created, and then use it in multiple places. For instance you could create a Fudge die, and then print it, plot it, and compute the sum of 5 of them:

fudge = d{-1, 0, 1}

print "A fudge die:"
print(fudge)
plot(fudge, "1dF")
plot(5 * fudge, "5dF")

-- We've seen that some basic operations are already defined. For anything more complicated, you'll need to modify existing dice. The way to do that is with the "apply" method. You pass it a function, and the result will be a new die, obtained from applying that function to each of its outcomes.

-- As a basic example, let's compute d6 + 3 ourselves:

d6p3 = d6:apply(function(x)
    return x + 3
end)

-- And compare it to the built-in way of adding stuff to dice:

plot(d6p3, "Our way", d6 + 3, "The built-in way")

-- It works! The dice are exactly the same. Now to demonstrate what happens with the probabilities, let's roll a fudge die, and if the resut is negative, take its opposite:

plot(fudge:apply(function(x)
    if x < 0 then
        return -x
    else
        return x
    end
end), "1dF modified")

-- The result 1 is now twice more likely than 0: indeed, there are two ways to obtain it (roll a 1 or a -1 on the fudge die).

-- Note that this function we wrote is called "absolute value", and it is already available in standard Lua as "abs". We could have written this more concise version and gotten the same result:

plot(fudge:apply(abs), "1dF modified, again")

-- You can find the list of all math functions in Lua in the manual: https://www.lua.org/manual/5.3/manual.html#6.7

-- As a last example, suppose you're rolling a d20, adding an attribute, and trying to roll over a certain value to check if you hit or miss an enemy. This could be a way to do it, returning strings for detailed descriptions:

print "d20 + 5 >= 23 ?"

print(d20:apply(function(x)
    if x + 5 >= 23 then
        return "hit"
    else
        return "miss"
    end
end))

-- This could have been written as follows:

print((d20 + 5):gte(23):apply(function(x)
    if x then
        return "hit"
    else
        return "miss"
    end
end))

-- Indeed, in addition to the basic math operators, dice come with methods for basic comparisons as well: lt (lower than), lte (lower than or equal), gt (greater than), gte (greater than or equal), eq (equal), neq (not equal). For arcane reasons, the normal comparison operators that work on numbers cannot be adapted to dice.

-- As a final note, here is a useful Lua idiom that can shorten things a little bit. "a and b or c" will evaluate to b if a is true, and c otherwise. So we could have written even more concisely:

print((d20 + 5):gte(23):apply(function(x)
    return x and "hit" or "miss"
end))
