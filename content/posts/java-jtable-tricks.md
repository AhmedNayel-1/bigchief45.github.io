---
date: '2017-12-20'
tags:
- java
title: Java JTable Tricks
---

Java's JTable is a GUI component that has been around for many many years. While a bit difficult to work with, it's almost a mandatory component in an application that displays a lot of data.

In this post I share some nice tricks for working with JTables in Java applications.

## Scrolling

A JTable by itself does not provide any scrolling when handling a lot of data. To fix this, we need to place the table inside a `JScrollPane` component. Additionally, we can place this `JScrollPane` into a `JPanel` in our window:

```java
myPanel.add(new JScrollPane(myTable,
    JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED,
    JScrollPane.HORIZONTAL_SCROLLBAR_AS_NEEDED)
    );
```

<!--more-->

Notice how we are specifying vertical and horizontal scrollbars on a _as needed_ basis.

## Adding New Blank Rows

Adding new blank rows at run time is easy. We can use the `addRow()` method from the table's model:

```java
DefaultTableModel model = (DefaultTableModel) myTable.getModel();
model.addRow(new Object[] {});
```

## Removing Selected Rows

We can make a selection of multiple rows and delete them at runtime:

```java
int numRows = myTable.getSelectedRows().length;
DefaultTableModel model = (DefaultTableModel) myTable.getModel();

for (int i = 0; i < numRows; i++) {
    model.removeRow(myTable.getSelectedRow());
}

myTable.clearSelection();
```

## File Type Cells

Let's say we want to associate a file to each record from the table. To do this, we can add a special column that will contain the File object, and to select this file we want to use the super useful `JFileChooser` component.

To achieve this, we need to set a custom cell editor to the column. Assuming we know the index of this special column, we can set it like this:

```java
myTable.getColumnModel().getColumn(index).setCellEditor(new FileChooserCellEditor());
```

We will have to manually create and define this `FileChooserCellEditor` class in a `FileChooserCellEditor.java` file:

<script src="https://gist.github.com/BigChief45/4aefbece5d88182424123a3a50519cf2.js"></script>

With this implementation you can now double click on the cell, and a nice file chooser will appear. After selecting the file, its absolute path value will be assigned and shown in the cell.