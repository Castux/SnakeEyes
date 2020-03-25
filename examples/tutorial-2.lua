-- To create a die, you have several options. We've already seen that all dice of the form "dN" are already available right out of the box:

plot(d2, "d2", d6, "d6", d23, "d23")

-- The function "d" can be used for all the rest. Its first form is to just pass it a number:

plot(d(4), "d4", d(2 * 3), "d6")

-- Its second form is to pass a list of possible outcomes. They will be assumed to be equiprobable:

plot(d{1,3,4,7,8}, "Some funky die")

-- Its last form is to pass a list of outcomes, *and* their relative probabilities. This one rolls 1's three times more often than 2's, 3's or 5's, and 4's twice as often as 2's, 3's or 5's.

plot(d({1,2,3,4,5}, {3,1,1,2,1}), "A loaded die")

-- The outcomes of the dice can also be strings. Although note that in that case, outcomes will be sorted lexicographically (comparing letter by letter) for the purposes of computing the cumulative distributions.

plot(d({"skull", "flower", "dagger"}, {3, 1, 2}), "A die with symbols")
