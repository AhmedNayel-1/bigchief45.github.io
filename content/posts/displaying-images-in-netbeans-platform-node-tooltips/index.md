---
date: '2018-08-14'
tags: [netbeans platform]
title: Displaying Images in Netbeans Platform Node Tooltips
---

Netbeans Platform allows you to display HTML inside a node's tooltip text. Naturally this means you can display images. For example, project nodes in the Netbeans IDE display icons related to errors (if there are any) and version control:

![Netbeans Node Tooltip Images](/posts/displaying-images-in-netbeans-platform-node-tooltips/node_tooltip_images.png)

Achieving this is not very straight forward, since the documentation doesn't really say much on how to load this image. Fortunately it is very simple.

<!--more-->

All the work will be done inside the node's `getShortDescription()` method. We will build a string in HTML format that contains a `<img>` tag that points to our image.  The image's location will be handled using a `URL` object.

Here is a complete example of how we can achieve is:

```java
public final class MyNode extends BeanNode<MyObject> {

  public static final String MY_ICON = "com/myapp/mypackage/icon.png";

  public MyNode(MyObject bean) throws IntrospectionException {
    // Initialization with factory here
  }

  @Override
  public String getShortDescription() {
    URL iconUrl = getClass().getClassLoader().getResource(MY_ICON);

    String s = "<html>";
    s += "<p><img src=\"" + iconUrl + "\"> Custom message</p>";
    s += "</html>";

    return s;
  }
}
```

Notice how we escape double quotes.