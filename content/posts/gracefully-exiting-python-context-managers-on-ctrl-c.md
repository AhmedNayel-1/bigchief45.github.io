---
title: "Gracefully Exiting Python Context Managers on Ctrl+C"
date: 2020-04-10T16:27:41-06:00
tags: [python]
---

In this post I will show you how you can exit gracefully from within a context manager in your Python application.

Suppose that we provide a context manager that can be used as a session to perform certain tasks. When the context manager is closed, there is some cleanup work to be done. We want this to happen even when the user interrupts the program with <kbd>Ctrl+C</kbd> key.

This is how we can achieve that:

<!--more-->

```python
import sys
import time
from signal import signal, SIGINT


class Session:

    def __enter__(self):
        signal(SIGINT, self._sigint_handler)

        time.sleep(100000000000)

    def __exit__(self, type, value, traceback):
        print('Exiting session...')

        self._do_cleanup()

    def _do_cleanup(self):
        print('Cleaning up...')

    def _sigint_handler(self, signal_received, frame):
        print('Ctrl + C handler called')

        self.__exit__(None, None, None)
        sys.exit(0)


if __name__ == '__main__':
    with Session():
        print('Session started')
```

If you run the program above, the program will sleep and block for a long time. When you press <kbd>Ctrl+C</kbd>, the handler we registered (`_sigint_handler`) will be called instead of a `KeyboardInterrupt` error being raised. In this method we **manually** call the context manager's `__exit__` method, passing a value of `None` for all 3 arguments. This is what is actually passed when `__exit__` is routinely called when the context manager is finished.

Notice that after manually calling `__exit__`, we are also manually terminating the program with `sys.exit(0)`. This is necessary, since omitting this will cause our program to keep running. Pressing <kbd>Ctrl+C</kbd> **will not terminate the program**.