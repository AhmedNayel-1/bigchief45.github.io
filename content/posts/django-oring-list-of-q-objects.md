---
title: "Django: ORing List of Q Objects"
date: 2019-08-02T16:34:42-06:00
tags: [django]
---

Django allows using the OR bitwise operator `|` with `Q` objects for more complex lookups:

```python
Q(question__startswith='Who') | Q(question__startswith='What')
```

However this requires explicitely typing each `Q` object. How can we apply this OR opperation to all the `Q` objects in a list?

In Python 3 we can do so like this:

```python
from functools import reduce
from operator import __or__


qs = MyModel.objects.filter(reduce(__or__, filters))
```

Where `filters` is a list containing multiple `Q` objects like the ones shown in the first example.

## References

1. http://simeonfranklin.com/blog/2011/jun/14/best-way-or-list-django-orm-q-objects/
