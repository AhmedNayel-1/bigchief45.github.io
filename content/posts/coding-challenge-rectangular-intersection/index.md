---
title: "Coding Challenge: Rectangular Intersection"
date: 2019-04-09T18:07:34Z
tags: [codingchallenges]
---

**Difficulty:** Easy

## Problem

Given two rectangles, write a function that can find the rectangular intersection between the two rectangles. The rectangles are always straight and never diagonal (each side is parallel with either the x axis or the y axis). Consider only positive axis.

![Rectangular Intersection](/posts/coding-challenge-rectangular-intersection/rectangular_intersection.png)

The rectangles are defined as a `Rectangle` class as shown below:

```
Rectangle(left_x, bottom_y, width, height)

# Example
r = Rectangle(2, 7, 30 8)
```

Your output rectangle should be returned using this format.

<!--more-->

## Analysis

This seems like a problem where you have to perform many calculations around both rectangles to try and find the intersection points.

Surprisingly there is an easier and simpler way, but it was not very easy to spot for me.

If you put the x axis points from both rectangles into a list and **sort** them, and then do the same for the y axis points for both rectangles, you can find the points of the intersection rectangle pretty easily.

The points of the intersection rectangle will be the **two middle** points of each list, if the rectangles overlap.

With this information we can easily calculate the intersection rectangle's width and height with some simple subtraction and return an answer.

:warning: This method will only work if the triangles overlap. So before we try to find an intersection rectangle, we must first determine if the rectangles overlap or not. We will do this by substracting the right-hand side to the farthest left minus the largest left-hand side to the farthest right.

## Solution (Python):

I will include the `Rectangle` class definition with some additional helper methods:

```python
class Rectangle:
    def __init__(self, left_x, bottom_y, width, height):
        self.left_x = left_x
        self.bottom_y = bottom_y
        self.width = width
        self.height = height

    @property
    def right_x(self):
        return self.left_x + self.width

    @property
    def top_y(self):
        return self.bottom_y + self.height


def rect_intersection(r1: Rectangle, r2: Rectangle) -> Rectangle:
    """
    Calculates and returns the rectangular intersection
    between two rectangles
    """
    # Check if rectangles overlap
    if min(r1.right_x, r2.right_x) - max(r1.left_x, r2.left_x) < 0:
        return None

    xs = sorted([r1.left_x, r1.right_x, r2.left_x, r2.right_x])
    ys = sorted([r1.bottom_y, r1.top_y, r2.bottom_y, r2.top_y])

    answ = Rectangle(
        left_x=xs[1],
        bottom_y=ys[1],
        width=xs[2] - xs[1],
        height=ys[2] - ys[1]
    )

    return answ


if __name__ == '__main__':
    r1 = Rectangle(5, 0, 10, 8)
    r2 = Rectangle(10, 5, 10, 10)

    answ = rectangular(r1, r2)

    print('Answer: ', answ)
    # Prints (10, 5, 5, 3)
```

## References

- [Amazon Coding Interview - Overlapping Rectangles - Whiteboard Wednesday](https://www.youtube.com/watch?v=zGv3hOORxh0)