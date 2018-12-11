---
date: '2018-04-23'
tags: [netbeans platform]
title: Creating Toolbars for MultiView Elements in Netbeans Platform
---

On a [previous post](/posts/custom-file-types-in-netbeans-platform.html) I talked about creating a new file type that Netbeans Platform can recognize and display the file's data in different ways by creating different visual editors that implement the `MultiViewElement` interface.

However, that tutorial did not cover how to add a custom toolbar to each multi view. Like the one Netbeans already provides when editing source code:

![Netbeans MultiView Toolbar](/posts/creating-toolbars-for-multiview-elements-in-netbeans-platform/netbeans_multiview_toolbar.png)

This is a very handy toolbar that can be used to add buttons that perform different kinds of actions with the current active file.

## A Deeper Look Into the MultiViewElement Object

If you recall from the previous post, a `JPanel` that implements `MultiViewElement` was created after finishing the wizard. This `MultiViewElement` object has some very important characteristics that are key to this tutorial:

<!--more-->

```java
public final class MyCustomVisualElement extends JPanel implements MultiViewElement {
  // ...
  private JToolBar toolbar = new JToolBar();

  // ...

  @Override
  public JComponent getToolbarRepresentation() {
      return this.toolbar;
  }
}
```

As you can see, the creation of this file includes a `JToolbar` component inside this `JPanel`, as well as a `getToolbarRepresentation()` method. This is how the visual element renders the toolbar for our data file.

## Creating the Toolbar

There are two ways we can create our custom toolbar and render it:

1. Write the code inside our `MultiViewElement` that adds all necessary buttons to the toolbar, each with their respective icons and actions defined, and return the toolbar in `getToolbarRepresentation`().
2. Create a separate `JPanel` component and create the toolbar inside that panel using Netbeans's GUI Builder (Matisse) which lets us drag and drop the necessary buttons to create the toolbar. Lastly we can return a new instance of this panel inside `getToolbarRepresentation()`.

I prefer the second approach, since it allows me to separate the toolbar code (which could be a lot, depending on how many actions you want to include) from the visual element code. The only trick with this approach is that you will probably need to pass the data object (among other things) to this new `JPanel`'s constructor'.

Having said that, let's go ahead and create a new JPanel Form in our module. Using the GUI Builder, drag and drop a `JToolbar` component, and then drag and drop the necessary buttons inside this toolbar. Here is an example:

![Custom Toolbar Example](/posts/creating-toolbars-for-multiview-elements-in-netbeans-platform/custom_toolbar_example.png)

To add the action logic to each button you can double click each button and then Netbeans will display the appropriate method to write your logic.

Assuming that I am working with a `TableModel` object, and the buttons in the toolbar can add or remove rows, the actions would need to have the correct reference to this table and its model. This implementation is really up to you, but we could easily pass these objects when instantiating the toolbar in the `MultiView` object:

```java
@Override
public JComponent getToolbarRepresentation() {
    return new MyCustomVisualElementToolbar(obj, dataTable);
}
```

Where `obj` is the custom data object (from the custom file type wizard) and `dataTable` is a `JTable` in the `MultiView` visual element object.

After you build and run your application, you should see your custom toolbar when opening a file and selecting the right view element that contains the toolbar. When clicking the buttons, the respective action logic should be executed.