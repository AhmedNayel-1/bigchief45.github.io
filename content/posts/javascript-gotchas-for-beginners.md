---
date: '2017-01-06'
tags:
- javascript
- programming
title: JavaScript Gotchas for Beginners
---

When starting to learn JavaScript, there are a few details and gotchas that are always important to remember. Memorizing and understanding these concepts will make you a better and faster JavaScript programmer overall and it is why I am listing a few of these concepts (which are best learned at the beginner level) in this post.

## The Global Object

The **global scope** is the space in which global variables live and it can also be approached as an object. Each global variable is present as a **property** of this object. In browsers, the global scope object is stored in the `window` variable:

```javascript
var v = 10;
console.log("v" in window);
// > true
console.log(window.v);
// > 10
```

<!--more-->

## Objects and Mutability

With JavaScript objects there is a difference between having two references to the same object and having two different objects that contain the same properties. Consider the following code:

```javascript
var object1 = {value: 10};
var object2 = object1;
var object3 = {value: 10};

console.log(object1 == object2);
// > true
console.log(object1 == object3);
// > false

object1.value = 15;
console.log(object2.value);
// > 15
console.log(object3.value);
// > 10
```

This is why it is important to be careful when trying to "copy" variables like above, it leaves a lot of room for unexpected results.

## Prototypes

In JavaScript, almost all objects have a **_prototype_**, in addition to their set of properties. A prototype is another object that is used as a fallback source of properties. When an object gets a request for a property that it does not have, its prototype will be searched for the property, then the prototype's prototype, and so on.

The entity behind almost all objects is `Object.prototype`. The `Object.getPrototypeOf` function returns the prototype of an object.

A prototype can be used at any time to add new properties and methods to all objects based on it.

## Function Arguments

It is perfectly possible to call a function and pass more or fewer arguments than the number of parameters the function itself declares. When too many arguments are passed, the extra arguments are **ignored**:

```javascript
function noArguments() {}
noArguments(1, 2, 3); // all arguments are ignored
```

When fewer arguments are passed, the missing parameters simply get assigned the value `undefined`:

```javascript
function myFunction(first, second, third) {}
myFunction(1, 2); // 'third' would become undefined
```

Using a variable name starting with an underscore or consisting entirely of a single underscore is a way to indicate to human readers that this argument is not going to be used.

## The arguments Object

In JavaScript, whenever a function is called, a special variable named `arguments` is added to the environment in which the function body runs. This variable refers to an object that holds all of the arguments passed to the function.

The `arguments` object has a `length` property that tells us the number of arguments that were really passed to the function.

```javascript
function argumentCounter() {
  console.log("You gave me", arguments.length, "arguments.");
}

argumentCounter("Hello", "Hola", "Ciao");
// => You gave me 3 arguments.
```

## The instanceof Operator

JavaScript provides a binary operator called `instanceof` which determines whether an object was derived from a specific constructor or not:

```javascript
console.log(new TextCell("A") instanceof RTextCell);
// => false
console.log([1] instanceof Array);
// => true
```

## Strict Mode and Debugging

When debugging, we can make use of a special mode in JavaScript called **strict mode**. To use this mode, we can put the string "use strict" at the top of a file or function body. For example:

```javascript
function canYouSpotTheProblem() {
  "use strict";
  for (counter = 0; counter < 10; counter++)
    console.log("Happy happy");
}

canYouSpotTheProblem();
// => ReferenceError: counter is not defined.
```

In the example above, JavaScript would normally proceed to create a global variable and use that. In strict mode however, an error is reported instead.

We can also use the `debugger` keyword to set a breakpoint in the program. When using a browser's developer tools, the program will pause whenever it reachers that statement and we can inspect the program's state.

## Selective Exception Catching

When we want to catch specific exceptions in JavaScript, we can do so by first defining a new type of error and use `instanceof` to identify it. For example:

```javascript
function InputError(message) {
  this.message = message;
  this.stack = (new Error()).stack;
}
InputError.prototype = Object.create(Error.prototype);
InputError.prototype.name = "InputError";
```

We can throw the error inside a function:

```javascript
function throwError() {
  /* ... */
  throw new InputError("Invalid Error - InputError");
}
```

And we can catch it from another place in our code:

```javascript
/* ... */
try {
  var a = throwError();
} catch(e) {
  if (e instanceof InputError)
    console.log("An input error ocurred");
  else
    throw e;
}
```

## References

1. Eloquent JavaScript - Marijn Haverbeke