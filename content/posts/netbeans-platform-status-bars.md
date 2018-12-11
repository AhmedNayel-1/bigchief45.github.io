---
date: '2018-07-19'
tags: [netbeans platform]
title: Netbeans Platform Status Bars
---

In desktop applications, status bars are a great way to convey information to the user about the current status of certain items in the application, such as connection status, total amount of items, current mode, current row and column number in an editor, etc.

Implementing custom status bars to a Netbeans Platform application is extremely easy. In this article I will go over how we can achieve really cool things with status bars and lookups.

## Creating and Registering a New Status Bar

To create a new status bar, create a new Java class that implements the `StatusLineElementProvider` interface. To register it as a status bar, we use the `@ServiceProvider` annotation:

```java
@ServiceProvider(service = StatusLineElementProvider.class, position = 1)
public class MyStatusBar implements StatusLineElementProvider {

}
```

<!--more-->

There is only one method we need to implement: `getStatusLineElement()`. This method returns a Java Swing `Component` object, which is what the user will see in the status bar section of the application.

Depending on how much you want to display in your custom status bar, you can either just return a simple `JLabel` component that includes text (JLabels can also include icon, among other things), or you can create a `JPanel` and put everything you want to display there and return it.

If you choose the `JPanel` approach, you can  then create a new class that extends `JPanel`, using the Netbeans IDE. Then in the `getStatusLineElement()` method we will simply return a new instance of this panel:

```java
@ServiceProvider(service = StatusLineElementProvider.class, position = 1)
public class MyStatusBar implements StatusLineElementProvider {

    @Override
    public Component getStatusLineElement() {
        return new MyStatusBarPanel();
    }
}
```

In the design view (Matisse view) of Netbeans IDE you can drag and drop multiple components into your JPanel.

## Making Status Bars Dynamic Using Lookups

So far our status bar can display information to the user. However if this information is bound to change, the status bar will not be aware of this change and will not display newer information accordingly. Therefore we need to make our status bar to be able to listen to changes on what we are displaying. This will vary depending on what we are listening on and its implementation. For this example we will assume we just want to display a simple counter of objects in a lookup.

To be able to listen to changes in a lookup, we use the `LookupListener` interface in our consumer object. In this case our consumer object can be our `JPanel`. To use this interface we need to:

1. Specify which lookup we are listening on.
2. Implement the `resultChanged` method to do something when the lookup's content changes.

Here is an example of that:

```java
import org.openide.util.Lookup.Result;

public class MyStatusBarPanel extends javax.swing.JPanel implements LookupListener {

    private Result<MyClass> result;

    public MyStatusBarPanel() {
        initComponents();

        // In this example we are using a custom lookup. But you can also
        // use the Netbeans Platform default lookup as well.
        result = MyLookup.getDefault().lookupResult(MyClass.class);
        result.addLookupListener(this);
    }

    @Override
    public void resultChanged(LookupEvent evt) {
        // For our example we simply get the result count
        int count = result.allInstances().size();

        // Assuming you have already dragged and dropped swing components
        // into the JPanel, we will set the count in a JLabel to display
        // it.
        labelCounter.setText("Total items: " + count);
    }
}
```

With this implementation the status bar's displayed counter will always be up to date with changes in the item count of the lookup.