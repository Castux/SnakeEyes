---
layout: default
title: docs
---

# {{ site.title }} documentation

{{ site.title }} is a web-based calculator for dice probabilities. You write a small program that describes how to roll the dice, and it computes all the possible outcomes and their probabilities. It can also draw graphs to display the results.

This is a complete reference documentation. To learn how to use {{ site.title }}, you might want to read the tutorials and examples first.

## Introduction

Programs in {{ site.title }} are written in the Lua programming language. The tool is actually a full-featured Lua 5.3 interpreter that includes a dice probabilities computation library, graphing tools and convenient shortcuts.

You can refer to the [reference manual for Lua 5.3](https://www.lua.org/manual/5.3/) for any questions concerning the language itself.

This documentation describes essentially the dice probabilities library and the environment setup for the web tool, which provides a few global functions, and introduces two object classes: `Die` and `DiceCollection`.

## Automatic conversion

Throughout the library, wherever a `Die` object is expected, one can provide a single value instead (number, string or boolean), and it will be converted to a `Die` object with that single outcome.

Similarly, instead of a `Die`, one can provide a `DiceCollection`, which will be converted to a single `Die` via the `sum` method.

## Nested dice

When creating a die with `d(outcomes)`, outcomes can be themselves `Die` objects. In that case, the nested dice are flattened: it corresponds to the idea of replacing the result with the outcome of another die. For instance, `d{1,2,3,d6}` concisely expresses "roll a d4, and if a 4 comes up, roll a d6 instead".

Similarly, the function passed to `apply` can return `Die` objects instead of single values.

## Global functions

### d(n)

Returns a `Die` object with outcomes 1 to `n`, all equiprobable.

### d(outcomes [, probabilities])

Returns a `Die` object with given `outcomes`, and given relative `probabilities` (defaults to equiprobable). Outcomes can be numbers, string, booleans or other `Die` objects. Different types of outcomes cannot be mixed in a single `Die`.

### dN

All globals `d1`, `d2`, `d3`, etc. (`d` followed by any number of digits) are pre-defined to the same result as `d(N)`.

###  abs, acos, ...

The entire contents of the Lua `math` library are in the global environment: `abs`, `acos`, `asin`, `atan`, `ceil`, `cos`, `deg`, `exp`, `floor`, `fmod`, `huge`, `log`, `max`, `maxinteger`, `min`, `mininteger`, `modf`, `pi`, `rad`, `random`, `randomseed`, `sin`, `sqrt`, `tan`, `tointeger`, `type`, `ult`

### write

Although the `io` library is not available, the `write` function is provided to replace `io.write`, and works similarly. `print` works as usual (placing tabs between its arguments).

### plot(die [, label])

Plots a single die: probabilities as a bar chart, and for a die with non boolean outcomes, the two cumulative distributions overlaid as lines. The optional `label` string is used in the plot's legend.

### plot(die1 [, label1], die2 [, label2], ...)

Plots the probabilities for multiple dice in a single plot, as lines. Each die can be followed by an optional string argument that will be used a label in the legend.

### plot_cdf(die1 [, label1], die2 [, label2], ...)

Similar to `plot` for multiple dice, but plots the cumulative distributions instead (probabilities of outcomes lower than or equal). Cannot be used with boolean-valued dice.

Alternatively, the function can take a single table argument containing the dice and labels.

### plot_cdf2(die1 [, label1], die2 [, label2], ...)

Similar to `plot` for multiple dice, but plots the opposite cumulative distributions instead (probabilities of outcomes greater than or equal). Cannot be used with boolean-valued dice.

Alternatively, the function can take a single table argument containing the dice and labels.

### plot_transposed(die1 [, label1], die2 [, label2], ...)

Plots multiple dice so that each die is a column of all its outcomes in a stacked bar chart. This can be useful to visualize and compare dice with a low number of outcomes.

Alternatively, the function can take a single table argument containing the dice and labels.

### plot_raw(labels, datasets, stacked, percentage)

The library exposes the internal plotting function, for maximum flexibility. `labels` is an array of labels (the X axis) and `datasets` is an array containing the datasets to plot. Each dataset should be an array of values (same size as `labels`) and can optionally contain the following fields:

- `label`: the name to use for the dataset in the legend
- `type`: by default the charts are bars, but this can be set to the string `"line"` or `"scatter"` instead

If `stacked` is true, the graph will be stacked bars and/or lines, and if `percentage` is true, the Y axis will be displayed as percentages instead of direct values.

### print_dice(die1 [, label1], die2 [, label2], ...)

A convenience function that will simply print the dice one after the other, preceded with their labels if any.

Alternatively, the function can take a single table argument containing the dice and labels.

In other words, it takes exactly the same arguments as the plot functions, and can be used to easily print out the same data that you plot.

## `Die` object

### Die:summary()

Returns a string that summarizes the die: the sorted list of outcomes with their probabilities, as well as the cumulative distributions (probability to be lower or higher than a given outcome).

This is what is also returned when a `Die` is converted to a string using `tostring` (and therefore when using `print` or `write`).

### Die:compute_stats()

Returns a table with the following fields:

- `boolean`: whether the die's outcomes are booleans or not
- `outcomes`: the sorted list of possible outcomes of this die (note that strings can be compared and sorted lexicographically in Lua)
- `probabilities`: the probabilities associated with the outcomes, in the same order
- `lte`: the cumulative distribution, that is, for each outcome, the probability of getting this outcome or a lower one (in the same order as `outcomes`)
- `gte`: the other cumulative distribution: for each outcome, the probability of getting this outcome or a higher one (in the same order as `outcomes`)

For dice with numerical outcomes, the table also has these fields:

- `average`: the average or expectation of the die
- `stdev`: the standard deviation

Fields `lte` and `gte` are omitted for boolean dice, and the `outcomes` table is not sorted, since booleans cannot be ordered.

### Die:percentile(n)

Computes the `n`-th percentile (with `n` between 0 and 1).

### Die:apply(func)

Returns a new `Die` by applying the given function to each outcome. See `DiceCollection:apply()`.

### ..

The concatenation operator is overloaded so that `a .. b` returns a `DiceCollection` made of dice `a` and `b`.

### Arithmetic operators

The usual arithmetic operators `+` `-` `*` `/` `//` `^` and `%` are overloaded for the `Die` object, and correspond to applying the given operations to the two operands. For instance, `a + b` is equivalent to `(a .. b):apply(function(x,y) return x + y end)`.

The `*` operator is an exception: if the left-hand side operand is a number N, the result is instead a `DiceCollection` containing N repetitions of the right-hand side operand.

The `-` operator also works as the unary operator for negation.

Due to limitations in operator overloading in Lua, the comparisons are available as methods instead:

- `lt` for operator `<`
- `lte` for operator `<=`
- `gt` for operator `>`
- `gte` for operator `>=`
- `eq` for operator `==`
- `neq` for operator `~=`

so that for instance `a:lt(b)` is equivalent to `(a .. b):apply(function(x,y) return x < y end)`.

### Die(outcome)

A `Die` object can be called like a function to get the probability of the given `outcome`. This will of course return 0 if the outcome is not possible on this die.

## `DiceCollection` object

`DiceCollection` objects are created with the `..` operator for `Die` and `DiceCollection` (eg. `a .. b .. c`), or multiplying a die to the left by a number (`4 * d5`).

The core method for `DiceCollection` is `apply`. Every other method is provided as a convenient shortcut for common dice computations.

### DiceCollection:apply(func)

This is the main way to transform and combine dice. `apply` enumerates all possible combinations of outcomes for the dice in the collection, along with the probability of each such combination. It returns a new `Die` object where outcomes are the results of calling function `func` on each combination of outcomes.

### DiceCollection:accumulate(func)

Applies `func` to the first two dice of the collection, then to the result and to the third die, then to the result of that and to the fourth die, etc.

This can be used to compute efficiently some common operations that can be done die by die instead of rolling all the dice first and applying the operation to the result.

See for instance `sum`, which is defined exactly as `collection:accumulate(function(x,y) return x + y end)`.

### DiceCollection:sum()

Returns the `Die` which is the sum of all dice in the collection.

### DiceCollection:count(value)

Counts occurrences of `value` in the outcomes of the dice of the collection. Alternatively, `value` can be a function, in which case `count` counts the number of outcomes for which that function returns true.

### DiceCollection:any(value)
### DiceCollection:all(value)
### DiceCollection:none(value)

Returns a boolean die indicating the probability of getting any/all/no outcome equal to `value`. Similarly, `value` can be a function, in which case the die describes the probability of any/all/no outcome to return true when passed to that function.

### DiceCollection:highest()
### DiceCollection:lowest()

Computes the distributions of the highest/lowest outcomes.
