# SuperDice documentation

SuperDice is a web-based calculator for dice probabilities. You write a small program that describes how to roll the dice, and it computes all the possible outcomes and their probabilities. It can also draw graphs to display the results.

This is a complete reference documentation. To learn how to use SuperDice, you might want to read the tutorials and examples first.

## Introduction

Programs in SuperDice are written in the Lua programming language. The tool is actually a full-featured Lua 5.3 interpreter that includes a dice probabilities computation library, graphing tools and convenient shortcuts.

You can refer to the [reference manual for Lua 5.3](https://www.lua.org/manual/5.3/) for any questions concerning the language itself.

This documentation describes essentially the dice probabilities library and the environment setup for the web tool, which provides a few global functions, and introduces two object classes: `Die` and `DiceCollection`.

## Automatic conversion

Throughout the library, wherever a `Die` object is expected, one can provide a single value instead (number, string or boolean), and it will be converted to a `Die` object with that single outcome.

Similarly, instead of a `Die`, one can provide a `DiceCollection`, which will be converted to a single `Die` via the `sum` method.

## Global functions

### d(n)

Returns a `Die` object with outcomes 1 to `n`, all equiprobable.

### d(outcomes [, probabilities])

Returns a `Die` object with given `outcomes`, and given relative `probabilities` (defaults to equiprobable). Outcomes can be numbers, string, booleans or other `Die` objects. Different types of outcomes cannot be mixed in a single `Die`.

### dN

All globals `d1`, `d2`, `d3`, etc. (`d` followed by any number of digits) are pre-defined to the same result as `d(N)`.

###  abs, acos, ...

The entire contents of the Lua `math` library are in the global environment: `abs`, `acos`, `asin`, `atan`, `ceil`, `cos`, `deg`, `exp`, `floor`, `fmod`, `huge`, `log`, `max`, `maxinteger`, `min`, `mininteger`, `modf`, `pi`, `rad`, `random`, `randomseed`, `sin`, `sqrt`, `tan`, `tointeger`, `type`, `ult`

## `Die` object

### Die:summary()

Returns a string that summarizes the die: the sorted list of outcomes with their probabilities, as well as the cumulative distributions (probability to be lower or higher than a given outcome).

### Die:compute_stats()

Returns a table with the following fields:

- `boolean`: whether the die's outcomes are booleans or not
- `outcomes`: the sorted list of possible outcomes of this die
- `probabilities`: the probabilities associated with the outcomes, in the same order
- `lte`: the cumulative distribution, that is, for each outcome, the probability of getting this outcome or a lower one (in the same order as `outcomes`)
- `gte`: the other cumulative distribution: for each outcome, the probability of getting this outcome or a higher one (in the same order as `outcomes`)

### Die:apply(func)

Returns a new `Die` by applying the given function to each outcome. See `DiceCollection:apply()`.

### ..

The concatenation operator is overloaded so that `a .. b` returns a `DiceCollection` made of dice `a` and `b`. If either operand is a number, it is converted to a constant `Die` first. If either operand is a `DiceCollection`, it is converted to a `Die` by computing its sum.

### + - *  / // ^ %

The usual arithmetic operators are overloaded for the `Die` object, and correspond to applying the given operations to the two operands. For instance, `a + b` is equivalent to `(a .. b):apply(function(x,y) return x + y end)`.

The `*` operator is an exception: if the left-hand side operand is a number N, the result is instead a `DiceCollection` containing N repetitions of the right-hand side operand.

The `-` operator also works as the unary operator for negation.

Due to limitations in operator overloading in Lua, the comparisons functions are available as methods instead:

- `lt` for operator `<`
- `lte` for operator `<=`
- `gt` for operator `>`
- `gte` for operator `>=`
- `eq` for operator `==`
- `neq` for operator `~=`

so that for instance `a:lt(b)` is equivalent to `(a .. b):apply(function(x,y) return x < y end)`.

### Die(outcome)

A `Die` object can be called like a function to get the probability of the given `outcome`. This will of course return 0 if the outcome is not possible on this die.
