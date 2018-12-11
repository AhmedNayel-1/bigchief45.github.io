---
date: '2018-05-22'
tags: [netbeans platform]
title: Using Listeners in Custom Netbeans Platform Wizards
---

[This tutorial](https://platform.netbeans.org/tutorials/nbm-wizard.html#validate) explains how you can add validation to your custom wizards in the Netbeans Platform. This works by setting a boolean variable to `false` and then throwing a `WizardValidationException` which will show an error message in the wizard, disabling the ability to click the _Next_ or _Finish_ buttons.

The problem with this is that after the above happens, there is no way to enable these buttons again. And the way to achieve this is not covered in that tutorial.

Therefore, in this blog post I will explain just how to do that.

<!--more-->

We will be working only with the controller class of each panel. When using the wizard to generate your wizard, these classes will typically have a class suffix like `WizardPanel1`.

Let's begin by first implementing the `DocumentListener` interface and add a Set of `ChangeListener`s:

```java
public class DoSomethingWizardPanel1 implements WizardDescriptor.ValidatingPanel<WizardDescriptor>, DocumentListener {

  private Set<ChangeListener> listeners = new HashSet(1);

  // ...
}
```

Second, in the `getComponent()` method we will need to add the `DocumentListener` to each of the fields we want to trigger the change. For this example I will use a single text field:

```java
@Override
public DoSomethingVisualPanel1 getComponent() {
    if (component == null) {
        component = new DoSomethingVisualPanel1();
        component.getNameField().getDocument().addDocumentListener(this);
    }
    return component;
}
```

With the above implementation you will need to define a getter method `getNameField()` that returns the text field, inside the actual panel class that was also generated.

Next we will need to include some listener implementations:

```java
@Override
public void addChangeListener(ChangeListener l) {
    synchronized (listeners) {
        listeners.add(l);
    }
}

@Override
public void removeChangeListener(ChangeListener l) {
    synchronized (listeners) {
        listeners.remove(l);
    }
}

public void fireChangeEvent() {
    Set<ChangeListener> ls;
    synchronized (listeners) {
        ls = new HashSet(listeners);
    }

    ChangeEvent ev = new ChangeEvent(this);
    for (ChangeListener l : ls) {
        l.stateChanged(ev);
    }
}
```

Next, the `DocumentListener` implementation:

```java
@Override
public void insertUpdate(DocumentEvent de) {
    change();
}

@Override
public void removeUpdate(DocumentEvent de) {
    change();
}

@Override
public void changedUpdate(DocumentEvent de) {
    change();
}
```

The `change()` method is as follows:

```java
private void change() {
    setValid(true);
}
```

And lastly the `setValid` method that will re-enable the buttons:

```java
private void setValid(boolean val) {
    isValid = val;
    fireChangeEvent();
}
```

If the user input fails validation when the next/finish buttons are clicked again, the exception will be thrown again and the buttons will be disabled again. When the user types in the text field again, the listeners will work their magic, enabling the buttons once again.

## References

1. https://platform.netbeans.org/tutorials/nbm-wizard.html
2. https://blogs.oracle.com/geertjan/disablingenabling-a-wizard-panels-finish-button