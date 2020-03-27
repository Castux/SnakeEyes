-- Many rolls in games involve re-rolls, or rolling a certain die depending on the results of another. This can be expressed in SuperDice by nesting dice. When building a die, instead of giving a basic value for an outcome, you can give a whole other die:

nested = d{1,2,3,d10}

print "Roll a d4. On a 4, roll a d10 instead"
print(nested)

-- Same goes when using apply. Instead of returning a single value, you can return a die. The same example can be expressed as follows:

nested2 = d4:apply(function(x)
    if x < 4 then
        return x
    else
        return d10
    end
end)

plot(nested, "Same thing")

-- Many cool things can be written that way.

plot(d10:apply(function(x)
    if x < 8 then
        return x
    else
        return x + d4
    end
end), "d10, add a d4 on 9-10")

plot(d6:apply(function(x)
    return x * d10
end), "(d6)d10")

plot(d10:apply(function(x)
    return 5 * d(x)
end), "5d(d10)")

-- Including the famous exploding dice. Roll a die, if some condition is met, reroll it and add the result. If the condition is met again, keep rerolling and adding the results. We'll use a helper function for this one:

function explode(die, condition, rerolls)

    if rerolls == 0 then
        return die
    end

    local nextRoll = explode(die, condition, rerolls - 1)

    return die:apply(function(x)
        if condition(x) then
            return x + nextRoll
        else
            return x
        end
    end)
end

plot(explode(d10, function(x) return x >= 8 end, 5), "d10 explode on 8-10, max 5 rerolls")
