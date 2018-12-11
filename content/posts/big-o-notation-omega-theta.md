---
date: '2016-11-16'
tags:
- algorithms
- mathematics
- programming
- computerscience
title: Big O Notation - Omega & Theta
---

In a [previous post](/posts/ruby-benchmarking-and-big-o-notation.html) I went over the basic and most common Big O notations along with respective common algorithms, and finally adding some Ruby benchmarks for each.

However I did not cover some other very important concepts in Big O notation: **Omega** and **Theta**.

## Understanding Omega

The Omega symbol (Ω) represents a certain algorithm's *best-case* asymptotic complexity. For example, let's take again a look at the [binary search algorithm](https://en.wikipedia.org/wiki/Binary_search_algorithm):

![Binary Search vs Linear Search](https://blog.penjee.com/wp-content/uploads/2015/04/binary-and-linear-search-animations.gif)

Previously we determined that the Big O notation for this algorithm is *O(log n)*. This represent the **worst** asymptotic complexity that the algorithm can possibly have.

<!--more-->

However, if the element we are looking for is in the middle position of the array, binary search would find it in **constant time**. Thus, giving the binary search algorithm a complexity of Ω(1).

Similarly, **linear search** (also shown above) has an Omega complexity of Ω(1) because if the element we are looking for is the first element in the array, we would find it in constant time as well.

## Understanding Theta

Theta (Θ) describes algorithms where the best and worst cases are the same.

For example, if we have previously stored the length of a string in a variable, the only instruction necessary to get this value is to look at the variable. The best case would of course be in constant time, therefore the omega complexity would be Ω(1). For the worst case, it would **_still_** be constant time because we still need to only look at the variable, hence *O(1)*. This means that this particular "algorithm" has a theta complexity of Θ(1).

## Putting it Together

Because the O-complexity of an algorithm gives an **upper bound** for the actual complexity of an algorithm, while Θ gives the actual complexity of an algorithm, we sometimes say that the Θ gives us a **tight bound**.

From *[A Gentle Introduction to Algorithm Complexity Analysis](http://discrete.gr/complexity/)*:

> _If we know that we've found a complexity bound that is not tight, we can also use **small o** to denote that. For example, if an algorithm is Θ( n ), then its tight complexity is n. Then this algorithm is both O( n ) and O( n^2 ). As the algorithm is Θ( n ), the O( n ) bound is a tight one. But the O( n^2 ) bound is not tight, and so we can write that the algorithm is o( n^2 ), which is pronounced "small o of n squared" to illustrate that we know our bound is not tight._

Therefore, we can say that it's better if we can find tight bounds for our algorithms, as these give us more information about how our algorithm behaves. However, this is not always easy to do.

Basically we can say that Ω is used to specify lower bounds, and Θ is used to give a tight asymptotic bound on a function.

-> While all the symbols O, o, Ω, ω and Θ are useful at times, O is the one used more commonly, as it's easier to determine than Θ and more practically useful than Ω.