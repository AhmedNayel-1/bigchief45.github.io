---
date: '2018-03-28'
tags: [java, netbeans platform]
title: Custom File Types in Netbeans Platform
---

If your desktop Java application needs to deal with very particular or special kinds of files, we can make use of Netbeans Platform's custom File Type feature to define a file that our application can recognize, and display visual and editing components to view and edit the file's data.

Moreover, we can also make use of Netbeans Platform's _Favorites_ pane, which displays a tree view of a file system, where we can open the special files we need to work with.

## Creating a New Module

For this article, we are going to create a new file type for CSV (Comma Separated Value) files. When we open these files, our application will display a visual representation in the form of an editable JTable.

All this functionaltiy will live in its own Netbeans Platform Module. Meaning that it can be plugged in into different applications in a modular fashion.

We are going to create the module and build it using [Maven](https://maven.apache.org/), since we are also going to be adding some functionalities that depend on external libraries that we can easily include in our project with Maven. But you can also just create the module without Maven as well. To create the module go to _New Project > Maven > Netbeans Module_

<!--more-->

![New Maven Netbeans Module](/posts/custom-file-types-in-netbeans-platform/maven_netbeans_module.png)

We will name our module `CSVFileSupport`.Before creating the module, make sure to uncheck the _Allow OSGi bundles as dependencies_ option.

### Creating a New File Type: CSV File

At this point we have a brand new blank Maven module. To begin creating the new file type, right click on the module and select _New > File Type_ option to start the wizard.

In the wizard's first screen we need to enter the file's [MIME Type](https://en.wikipedia.org/wiki/MIME) and a space-separated list of its possible extensions:

![CSV File Recognition](/posts/custom-file-types-in-netbeans-platform/csv_file_recognition.png)

Lastly we will use `Csv` as the class name prefix, select an appropriate icon for the file type, and make sure that the _Use MultiView_ option is checked.

Once the wizard is finished, a [DataObject](http://wiki.netbeans.org/DevFaqDataObject) for our file type and a `VisualElement` file for our file type will be created. Since we do not really need the _Source_ panel in our view, you can go ahead and delete this code from `CsvDataObject` file:

```java
@MultiViewElement.Registration(
            displayName = "#LBL_Abc_EDITOR",
            iconBase = "com/elibro/csvfilesupport/books.png",
            mimeType = "text/abc",
            persistenceType = TopComponent.PERSISTENCE_ONLY_OPENED,
            preferredID = "Abc",
            position = 1000
    )
    @Messages("LBL_Abc_EDITOR=Source")
    public static MultiViewEditorElement createEditor(Lookup lkp) {
        return new MultiViewEditorElement(lkp);
    }
```

We can then add this module to a Maven Netbeans Platform application to see it in action. We can use the Favorites pane to browse some CSV files, they should be displayed with the icon we defined:

![CSV Files in Favorites](/posts/custom-file-types-in-netbeans-platform/favorites_csv_files.png)

If you open the file and check the _Visual_ pane to the right you will see that it's blank. We will go ahead and add some cool way to represent the data in the CSV file later.

Notice that you can open multiple files using the Favorites explorer. A new pane will be opened for each file. Let's go ahead and set the name of each file in its corresponding pane. Open the `CsvVisualElement` object and select the _Source_ pane. We are going to create a private variable inside the `CsvVisualElement` class to store the current file, and then set it in the class's constructor:

```java
public final class CsvVisualElement extends JPanel implements MultiViewElement {

    // ...
    private final File csvFile;

    public CsvVisualElement(Lookup lkp) throws IOException {
        obj = lkp.lookup(CsvDataObject.class);
        assert obj != null;
        initComponents();

        csvFile = FileUtil.toFile(lkp.lookup(DataObject.class).getPrimaryFile());
    }
}
```

We can then set the file's name as the display name in the `setMultiViewCallback` method of the class:

```java
@Override
public void setMultiViewCallback(MultiViewElementCallback callback) {
    this.callback = callback;
    callback.getTopComponent().setDisplayName(csvFile.getName());
}
```

And it should look like this:

![File Display Name](/posts/custom-file-types-in-netbeans-platform/file_display_name.png)

### Displaying the CSV Data

Before we get into the real visual stuff, let's first go ahead and implement the parsing functionality of the file. We will go ahead and create a new Java Class called `CSVManager` in the same package as the rest of the files. This class will take the file in its constructor, and it will contain many methods that work with the file.

```java
public class CSVManager {

    private File csvFile;

    public CSVManager(File file) {
        csvFile = file;
    }

}
```

Since we will want to display the data in a table, let's create a method that parses the CSV file and returns a table model of the data. To parse the file we will use the [OpenCSV](http://opencsv.sourceforge.net/) library:

```java
public DefaultTableModel CSVToTableModel() throws IOException {
    // The RFC4180ParserBuilder allows us to parse '\' characters.
    CSVReader csvReader = new CSVReaderBuilder(new FileReader(csvFile))
            .withCSVParser(new RFC4180ParserBuilder().build())
            .build();

    List<String[]> csvData = csvReader.readAll();
    Object[] headers = (String[]) csvData.get(0);
    csvData.remove(0);

    String[][] rowData = csvData.toArray(new String[0][]);

    return new DefaultTableModel(rowData, headers);
}
```

=> In the example above we are using a `DefaultTableModel`, but you will probably want to implement your own custom table model by extending `AbstractTableModel`.

We can then create class local variables in `CsvDataObject` to store the manager and the table model, initialize them in the constructor, and create the corresponding getter methods for each:

```java
public class CsvDataObject extends MultiDataObject {
    private final CSVManager csvManager;
    private final DefaultTableModel csvTableModel;

    public CsvDataObject(FileObject pf, MultiFileLoader loader) throws DataObjectExistsException, IOException {
        super(pf, loader);
        registerEditor("text/csv", true);

        csvManager = new CSVManager(FileUtil.toFile(this.getPrimaryFile()));
        csvTableModel = csvManager.CSVToTableModel();
    }

    public CSVManager getCSVManager()  {
        return this.csvManager;
    }

    public DefaultTableModel getTableModel() {
        return this.csvTableModel;
    }

    // ...
}
```

Open the `CsvVisualElement` file again and in the _Design_ pane, drag a new `JScrollPane` component into the panel. Then drag a `JTable` component inside the scroll pane. Now go to the file's source and in the `getVisualRepresentation()` method we will set the new model to the table:

```java
@Override
    public JComponent getVisualRepresentation() {
        dataTable = new JTable(obj.getTableModel());
        return this;
    }
```

If we run the application again and select a CSV file that contains actual data, you should see the rendered table with the file's data:

![CSV Data in Table](/posts/custom-file-types-in-netbeans-platform/csv_jtable_data.png)

### Implementing a Save Feature

We will want to be able to save the contents of the current file that is selected in the editor window. We can make use of Netbeans Platform's `Savable` interface to easily achieve this. First, make the `CsvDataObject` class implement the `Savable` interface:

```java
public class CsvDataObject extends MultiDataObject implements Savable {
    // ...
}
```

And lastly add your custom implementation of the `save()` method. For our CSV example, I am gonna add a method in the `CSVManager` that writes the data in the table model to the file in CSV format:

```java
public class CSVManager {

    // ...

    public void TableModelToCSVFile(TableModel tableModel) {
        try (FileWriter fileWriter = new FileWriter(csvFile)) {

            // Write the headers
            List<String> headers = new ArrayList();
            for (int i = 0; i < tableModel.getColumnCount(); i++) {
                headers.add(tableModel.getColumnName(i));
            }

            fileWriter.write(String.join(",", headers));
            fileWriter.write("\n");

            // Write the data
            for (int i = 0; i < tableModel.getRowCount(); i++) {
                List<String> row = new ArrayList();
                for (int j = 0; j < tableModel.getColumnCount(); j++) {
                    Object val = tableModel.getValueAt(i, j);

                    if (val == null) {
                        row.add("");
                    }
                    else {
                        row.add(tableModel.getValueAt(i, j).toString());
                    }
                }
                fileWriter.write(String.join(",", row));
                fileWriter.write("\n");
            }
        }
        catch (IOException e) {
            System.err.println(e.getMessage());
        }
    }
}
```

And then we can use that in the `save()` method of `CsvDataObject`:

```java
@Override
public void save() throws IOException {
    this.csvManager.TableModelToCSVFile(this.csvTableModel);
}
```

## References

- https://www.youtube.com/embed/rKL_dShhbkA
- https://platform.netbeans.org/tutorials/nbm-filetype.html
- https://stackoverflow.com/questions/24554753/how-do-i-handle-file-saves-properly-in-netbeans-platform-project-plugin
- https://platform.netbeans.org/tutorials/nbm-porting-basic.html