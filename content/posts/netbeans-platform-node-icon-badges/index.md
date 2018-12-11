---
date: '2018-05-03'
tags: [netbeans platform]
title: Netbeans Platform Node Icon Badges
---

The Netbeans IDE has some very cool way of letting users know when a certain file contains errors. For example, if you are editing a Java file and the file contains syntax errors, Netbeans will change the file icons with a new icon indicating errors:

![Netbeans Error Icons](/posts/netbeans-platform-node-icon-badges/netbeans_error_icons.png)

You can see that the error icons propagate all the way up to the top-most parent, the project itself.

## Netbeans Platform Icon Badges

As a user of the Netbeans IDE and before even knowing what the Netbeans Platform was, I always assumed that the normal state of the icon and the error state of the icon were two completely different icons handled by Netbeans. A few days ago I learned that this is not the case.

Netbeans uses the concept of **icon badges** to display these kind of error icons. Icon badges are basically multiple images merged together _at runtime_ into a single `Image` object.

In this article I want to quickly go over how you can apply this concept in your Netbeans Platform application when using the Nodes API.

<!--more-->

## Icon Badges With Nodes

When defining a node class in Netbeans Platform, there is a method called `getIcon` which you can define yourself so that when the nodes are rendered in the application, the default node icons will be replaced with the icon of your choosing. For example:

```java
public class MyBeanNode extends BeanNode<MyBean> {
  // Constructor and other stuff here...

  @Override
  public Image getIcon(int type) {
    return ImageUtilities.loadImage("path/to/my/icon");
  }
}
```

To apply the concept of badging, we can simply use the `mergeImages` method from `ImageUtilities`. To determine whether the method needs to merge an error badge icon or not will depend on how you are handling current errors for the nodes. Here is a very basic example:

```java
public class MyBeanNode extends BeanNode<MyBean> {

  private final Image ERROR_BADGE = ImageUtilities.loadImage("path/to/error/badge/icon");

  // ...

  @Override
  public Image getIcon(int type) {
    Image icon = ImageUtilities.loadImage("path/to/my/icon");

    if (getBean().hasErrors()) {
      icon = ImageUtilities.mergeImages(icon, ERROR_BADGE, 7, 7);
    }

    return icon;
  }
}
```

In the above example we are relying on a `hasErrors` method in the `MyBean` object, which is obtained by calling `getBean()`. Keep in mind that this may or may not be the best way to handle these errors.

Now when the factory object gets called again to render the nodes, nodes that contain errors will have their original icons merged with the error badge icon.

## References

1. http://wiki.netbeans.org/BadgedIcons
2. https://platform.netbeans.org/tutorials/nbm-povray-8.html