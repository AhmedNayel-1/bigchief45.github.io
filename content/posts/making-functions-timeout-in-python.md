---
title: "Making Functions Timeout in Python"
date: 2019-02-06T16:02:35Z
tags: [python]
keywords: [python]
---

Sometimes you need to execute a function that can take a lot of time to finish. You are not sure exactly when the function will finish, but you do not want to wait too long, or let your program "hang" waiting for a response.

We want our function to run for a certain period of time, and if this time limit is exceeded, we want to regain control of the program's execution.

We can achieve this by using a custom [context manager](http://book.pythontips.com/en/latest/context_managers.html) and the [`signal`](https://docs.python.org/2/library/signal.html) module from the standard library.

Here is a complete example:

<!--more-->

```python
import signal


class timeout:
    def __init__(self, time):
        self._time = time

    def __enter__(self):
        # Register and schedule the signal with the specified time
        signal.signal(signal.SIGALRM, timeout._raise_timeout)
        signal.alarm(self._time)
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        # Unregister the signal so it won't be triggered if there is
        # no timeout
        signal.signal(signal.SIGALRM, signal.SIG_IGN)

    @staticmethod
    def _raise_timeout(signum, frame):
        raise TimeoutError
```

Most implementations I found in StackOverflow place the `raise_timeout` function outside. However, I prefer to have it nicely encapsulated by implementing it as a static method of the context manager :thumbsup:

Now we can use our context manager like this:

```python
import time


if __name__ == '__main__':
    try:
        with timeout(5):
            time.sleep(10)
    except TimeoutError:
        print('The function timed out')

    print('Done.')
```

Since we are sleeping for 10 seconds (which exceeds the 5 second timeout limit), the code above will timeout and raise the `TimeoutError` error.

If you reduce the sleep time, or increase the timeout time, the function should be able to reach the last print statement.

There we have it! A simple way to timeout or long running functions in Python :tada:
