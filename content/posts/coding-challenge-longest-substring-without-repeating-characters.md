---
title: "Coding Challenge: Longest Substring Without Repeating Characters"
date: 2019-04-08T15:09:13Z
tags: [codingchallenges]
---

Here is a coding challenge from a recent technical interview.

**Difficulty:** Easy

## Problem

Given a string, find the length of the longest substring without repeating characters.

Examples:

- Given `abcabcbb`, the answer is `abc`, which the length is 3.
- Given `bbbbb`, the answer is `b`, with the length of 1.
- Given `pwwkew`, the answer is `wke`, with the length of 3. Note that the answer must be a **substring**, `pwke` is a _subsequence_ and not a substring.


<!--more-->

## Analysis

*Note: In the 3rd example, another possible solution is also `kew`*.

A possible approach to solve this problem is to separate the string into substring groups. We can start with a big group (length - 1) so that we might find the answer earlier.

For example, using the 3rd example given, we can split the string initially like this:

```python
['pwwkew', 'w']
```

At the beginning, the right part of the split will be smaller than the left one. But with each iteration, the left part will become smaller and the right part will become bigger until they are of equal size.

Here's an example of how that looks:

```python
['pwwkew', 'w']  # 1st iteration
['pwwk', 'ew']  # 2nd iteration
['pww', 'kew']  # 3rd iteration, answer: 'kew'
['pw', 'wk', 'ew']  # 4th iteration (not reached)
['p', 'w', 'w', 'k', 'e', 'w']  # 5th iteration (not reached)
```

Then on each group, we simply need to check if it contains unique characters.

## Solution (Python)

Here is my solution using Python 3:

```python
def longest_substring(s: str) -> int:
    """
    Returns the length of the longest substring with unique
    chracters in a string 's'.
    """
    n = len(s) - 1
    while n > 0:
        # Split the string into groups of size n
        groups = [s[i:i+n] for i in range(0, len(s), n)]

        for g in groups:
            # Ignore the small substring groups
            if len(g) == n:
                # Check if they have unique characters
                # using a set
                if len(set(g)) == len(g):
                    return len(g)

        n -= 1
```

## References

- [Stack Overflow: Split string every nth character?](https://stackoverflow.com/questions/9475241/split-string-every-nth-character/51256966)