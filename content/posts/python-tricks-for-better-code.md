---
date: '2017-03-08'
tags:
- python
- programming
title: Python Tricks for Better Code
---

A compilation of very useful Python tricks for better code. All examples are Python 2.7 and Python 3 compatible unless stated otherwise.

## Enumerate

When working with items in a list and we want to print or handle each item's index, instead of using a counter variable:

```python
# Bad way
i = 0
for place in places:
    print(i, place)
    i += 1
```

We can use `enumerate` to improve our code:

```python
for i, place in enumerate(places):
    print(i, place)
```

`enumerate` returns a list of indexes along with each item in the list.

<!--more-->

## Using zip

Sometimes it happens that we have two different lists and we want to iterate through **both** of these two lists **at the same time**. An ugly approach to this situation is  to obtain the length of one of the lists first and then iterate through one of them, while handling the other list inside the loop:

```python
# Bad way
list_1 = ['123', 'KSQR', '12GKAL']
list_2 = ['65DD', '12DD', '123HGH']

for i in range(len(list_1)):
    a = list_1[i]
    b = list_2[i]
    print(a, b)
```

Instead, we can use `zip` for more concise and better looking code:

```python
for a, b in zip(list_1, list_2):
    print(a, b)
```

`zip` will take two or more lists and zip them together. This means that the resulting list will have pairs of each item from each list as a single item.

## Swapping Variable Values

When we want to swap the values between two variables, a common and unpractical approach is to create a third temporary variable to help with the swapping:

```python
a = 5
b = -5

# Bad way
tmp = a
a = b
b = tmp
```

We can improve this by using a technique called **tuple unpacking**:

```python
a, b = b, a
```

## Default Dictionary Values

When trying to obtain a value from a dictionary, is necessary to check first if the dictionary already has the key we are using to obtain the value, otherwise we will get a `KeyError` error.

Usually checks like these are done like this:

```python
# Bad way
if 'John' in salaries:
    salary_john = salaries['John']
```

However there is a better way using a dictionary's `get` function:

```python
salary_john = salaries.get('John', 0)
```

With the `get` function we can immediately get the value for the `'John'` key if it exists, while also providing a fallback value of `0` if the key is not in the dictionary.

## For ... else

Python `for` loops have a very useful `else` statement. In the context of loops in Python, the `else` statement means that if no break occurs, the code inside the `else` will be executed.

The main use case for this behaviour is to implement search loops, where you’re performing a search for an item that meets a particular condition, and need to perform additional processing or raise an informative error if no acceptable value is found:

```python
for x in data:
    if acceptable(x):
        break
else:
    raise ValueError("No acceptable value in {!r:100}".format(data))

    # Continue calculations with x
```

## File Reading

When opening files, it is very common to see a variable assigned with `open()` and reading the contents with another assignment and `read()`:

```python
# Bad way
f = open('todo.txt')
content = f.read()

for line in content.split('\n'):
    print(line)

f.close()
```

A better way is to use the `with` statement. The file object also adds support for iteration for more concise code:

```python
with open('todo.txt') as f:
  for line in f:
    print line
```

Everything that is inside the `with` "block" will be executed while the file is open. When this is finished, the file will be closed automatically.

## List Comprehensions

List comprehensions allow us to define a list's contents in-line without its declaration. Here is an example **without** using list comprehension:

```python
list = []
for i in (1, 2, 3):
    list.append(i)
```

And here is the same example using a list comprehension:

```python
list = [i for i in (1, 2, 3)]
```

Neat! We can use multiple `for` statements together and `if` statements to filter out items. Using list comprehensions instead of `for` loops is a nice way to quickly define lists.

## Advanced Unpacking

Similar to the tuple unpacking trick shown before, in Python 2 we can use advanced unpacking in the following way:

```python
a, b = range(2)
# a => 0
# b => 1
```

With **Python 3** we can also obtain the remainder of the sequence. We can actually obtain the remainder from anywhere in the list:

```python
a, *rest, b = range(10)
# a => 0
# *rest => [2, 3, 4, 5, 6, 7, 8, 9]
# b => 10

a, *rest, b = range(10)
# a => 0
# b => 9
# rest => [1, 2, 3, 4, 5, 6, 7, 8]
```

## Enum Classes

Enumerated types were added to the standard library in **Python 3.4+**, allowing us to do the following:

```python
from enum import Enum

class Color(Enum):
    red = 1
    blue = 2
    green = 3

red = Color.red
```

## References

1. [7 Simple Tricks to Write Better Python Code - Sebastiaan Mathôt](https://www.youtube.com/watch?v=VBokjWj_cEA)
2. [Else Clauses on Loop Statements](http://python-notes.curiousefficiency.org/en/latest/python_concepts/break_else.html)
3. [The Hacker's Guide to Python by Julien Danjou](https://thehackerguidetopython.com/)
4. [10 awesome features of Python that you can't use because you refuse to upgrade to Python 3](http://www.asmeurer.com/python3-presentation/slides.html#1)