---
date: '2017-11-16'
tags:
- java
title: Creating an Upload Progress Dialog in Java
---

Many Java file upload [tutorials](http://www.codejava.net/coding/swing-application-to-upload-files-to-ftp-server-with-progress-bar) teach you how to show the current progress of a file upload using a JProgressBar in the user interface, usually placed in the main JFrame.

However I was trying make this much more visually appealing, like the way [WinSCP](https://winscp.net/eng/index.php) does it:

![SCP File Upload](/posts/creating-an-upload-progress-dialog-in-java/scp_file_upload.png)

This will require the use of another Swing class: JDialog. Basically the flow of the program will be like this:

1. Main class with main method calls `SwingWorker` class.
2. `SwingWorker` is in charge of doing the _actual_ upload. It will also create an instance of a `JDialog` to show the current upload progress.
3. `JDialog` class will contain the progress bar and other useful upload information.

<!--more-->

## Main Method

First things first. Our main method (or any method where you want to trigger the upload) will start the upload task:

```java
UploadTask uploadTask = new UploadTask(fileToUpload);
uploadTask.execute();
```

In the example above we are passing an array of files (`File`) we want to upload, to the constructor.

## Upload Task Class

We will create the `UploadTask` class which will be in charge of performing the Upload. For this example, I am going to simulate an upload to S3 using the Java AWS SDK, but this should work with any kind of upload (FTP, SFTP, etc. etc.):

```java
import javax.swing.SwingWorker;
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;


public class UploadTask extends SwingWorker<Void, Void> {

    private final File[] filesToUpload;
    private UploadProgressDialog uploadProgressDialog;


    public UploadTask(File[] files) {
        this.filesToUpload = files;

        addPropertyChangeListener(new PropertyChangeListener() {
            @Override
            public void PropertyChange(PropertyChangeEvent evt) {
                if ("progress".equals(evt.getPropertyName())) {
                    int progress = (Integer) evt.getNewValue();

                    uploadProgressDialog.setProgress(progress);
                }
            }
        });
    }
}
```

This class will contain the array of files to upload, passed from the main method. Additionally, it will contain an instance of a `UploadProgressDialog` object (which we will soon define), this is the `JDialog` object where we will show our nice upload progress.

Moreover, notice how the class extends `SwingWorker`. This allows the class to perform a concurrent operation without making the GUI freeze when it is executing.

Also very important is the `PropertyChangeListener` that we are adding in the constructor. This listener will allow us to periodically receive the current progress of the upload, represented by an integer ranging from `0` to `100`.

### The Upload Process

Classes that extend `SwingWorker` will implement a method called `doInBackground()`, where the actual processing of the worker will take place. In this case, the file upload:

```java
@Override
protected Void doInBackground() throws IOException {
    // Initialize the progress dialog
    uploadProgressDialog = new UploadProgressDialog(someFrame, false);
    uploadProgressDialog.setVisible(true);

    // Upload each file in the array
    for (File f : filesToUpload) {
        uploadProgressDialog.setCurrentUploadingFile(f);

        // Upload to S3, using AWS SDK
        PutObjectRequest request = new PutObjectRequest(
            S3_BUCKET_NAME,
            String.format("%s", f.getName()),
            f
        );

        // The SDK comes with a Progress Listener as well, I am going to be
        // using it here to get the actual bytes being transferred
        request.withGeneralProgressListener(new ProgressListener() {
            long totalFileSize = f.length();
            long totalBytesTransferred = 0;
            int percentageCompleted = 0;

            @Override
            public void progressChanged(ProgressEvent event) {
                totalBytesTransferred += event.getBytesTransferred();
                percentageCompleted = (int) (totalBytesTransferred * 100.0 / totalFileSize);

                // This is a specific method of a SwingWorker class, it will
                // set the current progress which is an integer from 0 to 100
                setProgress(percentageCompleted);

                // Convenience method of our progress dialog class
                uploadProgressDialog.addBytesTransferred(totalBytesTransferred);
            }
        });
    }
}
```

The two key things to understand here is how we are using the `SwingWorker` class's `setProgress()` method with the current calculated progress. This is the exact value that the listener in the constructor receives.

Additionally we are also using the instance of the `UploadProgressDialog` class. If you remember well, we also call a `uploadProgressDialog.setProgress()` method from the listener so that the dialog knows the current progress as well.

Pay attention to the parameters passed to the `JDialog` [constructor](https://docs.oracle.com/javase/7/docs/api/javax/swing/JDialog.html#JDialog(java.awt.Frame,%20boolean)):

- `someFrame`: Could represent a `JFrame` from your program. This is the frame from where the dialog is displayed.
- `false`: Whether dialog blocks user input to other top-level windows when shown. **Very important** to set this to false.

Let's not forget to dispose the dialog once the `SwingWorker` finishes:

```java
@Override
protected void done() {
    uploadProgressDialog.dispose();
}
```

## The Progress Dialog Class

Lastly, let's design and implement the dialog which will show the upload progress similar to the SCP example I showed you.

We can easily design this dialog using [Netbeans IDE](https://netbeans.org/) and creating a new _JDialog Form_ file, set the class name to `UploadProgressDialog` (as per the example in this article) and then proceed to add the necessary labels and progress bars. This is an example from an application I am developing:

![Progress Dialog GUI](/posts/creating-an-upload-progress-dialog-in-java/progress_dialog_gui.png)

If you are wondering why it looks like that, it's because I am using the [Dracula Theme and Look & Feel for Netbeans](http://plugins.netbeans.org/plugin/62424/darcula-laf-for-netbeans).

Now let's take a brief look into the source of this class:

```java
import java.io.File;


public class UploadProgressDialog extends javax.swing.JDialog {

    private File currentUploadingFile;


    public UploadProgressDialog(java.awt.Frame parent, boolean modal) {
        super(parent, modal);
        initComponents();

        // Centers the dialog in the screen
        this.setLocationRelativeTo(null);
    }

    public void setCurrentUploadingFile(File f) {
        currentUploadingFile = f;

        lblFileName.setText(currentUploadingFile.getName());
    }

    public void setProgress(int p) {
        pgrsbrPartProgress.setValue(p);
        this.setTitle(p + "% Uploading");
    }
}
```

Simple enough. Here is an example of how all this would look when the application is running and file upload is taking place:

![Progress Dialog Working Example](/posts/creating-an-upload-progress-dialog-in-java/upload_progress_example.png)

## References

1. http://www.codejava.net/coding/swing-application-to-upload-files-to-ftp-server-with-progress-bar