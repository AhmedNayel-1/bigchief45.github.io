---
date: '2018-11-28'
tags: [netbeans platform]
title: Cancellable Tasks in Netbeans Platform
---

I was trying to implement cancellable tasks in Netbeans Platform using [this blog post](https://rubenlaguna.com/post/2010-01-18-cancellable-tasks-and-progress-indicators-netbeans-platform/) as reference.

However I never managed to make it work. The tasks's thread would never get interrupted even after the confirmation dialog, the task would just keep running.

After some digging on the Netbeans Platform and IDE [source code](https://github.com/apache/incubator-netbeans), I think I managed to find a way to properly and **easily** implement cancellable tasks.

<!--more-->

## The `Cancellable` Interface

The trick to making your tasks cancellable is by implementing the `Cancellable` interface and using a **request processor** and **progress handle** that's configured to be able to cancel a given task.

When the user cancels the task using the GUI, the `cancel()` method will be called, and this is where we will handle the logic to determine if the task was cancelled or not. Here is an example:

```java
import org.openide.util.Cancellable;
import org.netbeans.api.progress.ProgressHandle;

public final class MyCancellableTask implements Runnable, Cancellable {

  private final ProgressHandle progress;
  private boolean cancelled = false;

  public MyCancellableTask() {
    // Notice how we pass this same task as a 'Cancellable' object to the progress handle
    progress = ProgressHandle.createHandle("Executing MyCancellableTask", this);
  }

  @Override
  public void run() {
    progress.start();

    // Do some time consuming task
    for (int i = 0; i < Integer.MAX_VALUE; i++) {
      // We still check for interrupted thread just to be safe
      if (Thread.interrupted() || cancelled) {
        // In this case we can use break, but if there is more logic after the loop
        // then we should finish the progress handle and return
        break;
      }

      System.out.println("i = " + i);
    }

    progress.finish();
  }

  @Override
  public synchronized boolean cancel() {
    cancelled = true;
    return true;
  }

}
```

Notice how we are now handling the state of the task (if it's cancelled or not) using a boolean, instead of just relying on `Thread.interrupted()`.

We can now start this cancellable task like this:

```java
public class StartMyCancellableTaskAction implements ActionListener {

  public StartMyCancellableTaskAction() {

  }

  @Override
  public void actionPerformed(ActionEvent evt) {
    // Use a custom RequestProcessor, since we need to specify support for cancellable
    // tasks
    RequestProcessor rp = new RequestProcessor("MyCancellableTask", 1, true);
    MyCancellableTask task = new MyCancellableTask();
    rp.post(task);
  }
}
```

## References

1. [Cancellable tasks and progress indicators [Netbeans Platform]](https://rubenlaguna.com/post/2010-01-18-cancellable-tasks-and-progress-indicators-netbeans-platform/)
2. [Noodle Threads (threading, progress, console)](https://www.antonioshome.net/kitchen/netbeans/nbms-threads.php)
3. http://wiki.netbeans.org/BookNBPlatformCookbookCH0210#Using_Progress_Bar