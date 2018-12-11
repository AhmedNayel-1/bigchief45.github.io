---
date: '2017-02-07'
tags:
- c
- programming
title: C Gotchas For Beginners
---

Similar to [my post](/posts/javascript-gotchas-for-beginners.html) on some must-know concepts about JavaScript for beginners, this is a list of concepts that show how C differs from other programming languages. These are concepts that you **must** know if you are to become a good C programmer.

## Boolean Types

C actually does not have a boolean type. They are usually defined like this:

```c
#define BOOL char
#define FALSE 0
#define TRUE 1
```

However it is argued that it is a better practice to simply use integers instead (`0` and `1`).

## Memory Address of Array Elements

In C, arrays have a contiguous memory allocation. We can verify this by printing the memory addresses of each element of an array. We can do so using `&` to access the memory location of the array element:

```c
int main() {
  char vowels[] = {'a', 'e', 'i', 'o', 'u'};

  for (int i = 0; i < 5; i++) {
    printf("Address of vowel [%d]: %u\n", i, &vowels[i]);
  }

  return 0;
}
```

The above code will produces the following output for me:

<!--more-->

```
Address of vowel [0]: 3566467104
Address of vowel [1]: 3566467105
Address of vowel [2]: 3566467106
Address of vowel [3]: 3566467107
Address of vowel [4]: 3566467108
```

A character occupies **one byte** in memory. As you can see, the addresses of two consecutive elements of the array differ by **one**. The memory addresses might differ each time you run the program, therefore the output above will most likely differ from yours.

If you were using integer types instead of `char` types, the addresses would be increasing by 4 instead. This is because (in modern compilers) each integer element consists of 4 bytes.

## Integer Division

A division using positive integers `a / b` will  result in an integer division. However, if either `a` or `b` is negative, the result depends on the compiler (rounding can go toward zero or toward negative infinity in pre-C99; in C99+, the rounding goes toward `0`). The result has type `int`. `floor(a/b)` does the same division, converts the result to double, discards the (nonexistent) fractional part, and returns the result as a double.

**Source:** http://stackoverflow.com/questions/12240228/c-integer-division-and-floor

## Working With Strings

A C string is defined as a pointer to an array of characters. When declaring strings that we want to manipulate, we should declare tham as an array of **characters**:

```c
char name[] = "Andres Alvarez";
```

The empty `[]` tells the compiler to calculate the size of the array automatically. This also equals to declaring the array using the specific size of the string, however when doing the latter approach we need to account for the **string termination** character, which is a special character (equal to `\0`) that indicates the end of the string.

Strings can also be declared by using a pointer to a character array:

```c
char * name = "Andres Alvarez";
```

### Assigning new values

When we want to change a string value of a variable, we do so using the `strcpy` function. For example:


```c
char name[] = "Andres";
strcpy(name, "new string");
```

### Formatting with printf

When we want to achieve some kind of interpolation in a string, we can use the `%s` (for strings), `%c` for characters, and `%d` (for integers) markers with `printf` to do so:

```c
printf("%s is %d years old.\n", name, age);
```

## Functions

Functions in C must be defined before they are used in the code. It is preferable that they are declared first and implemented later. For example:

```c
/* Declare the function */
int launch(int code);

int main() {
  /* Call the function */
  printf("The value of launch is %d\n", launch(10));
}

/* Implement the function */
int launch(int code) {
  return code * 12300;
}
```

Functions that don't return values are declared using `void`, like in Java:

```c
void launch(int code) {
  printf("Launching...");
}

int main() {
  launch();
}
```

## Dynamic Memory Allocation

This is where the `malloc` function (which C is very known for) is used. The malloc function will request a block of memory from the heap. If the request is granted, the operating system will reserve the requested amount of memory.

To dynamically allocate a chunk of memory, an available pointer is needed. This pointer will store the location of the newly allocated memory, making it accessible by using this same pointer. The pointer can also be used the free the memory once it is no longer needed.

For example, we can dynamically allocate just enough memory to hold a certain type of structure in memory, and then obtain a pointer that points to this newly allocated data:

```c
typedef struct {
  char * brand;
  int year;
} vehicle;

vehicle * sedan = malloc(sizeof(vehicle));
```

If there is not enough memory available, the malloc function will return a `NULL`. If the request is granted a block of memory is allocated, the address of the reserved block will be placed into the pointer variable.

=> Always use `sizeof` when allocating memory. **Never** allocate specific amounts of memory like when using `malloc(4)` (Requesting 4 bytes). This will make your code much more portable.

We can then access and modify the pointer's members/attributes:

```c
sedan->brand = "Toyota";
sedan->year = 1990;
```

To release the memory and return it to the operating system so that it can be used for other purposes, we use `free`:

```c
free(sedan);
```

After the memory is released, the variable `sedan` will **_still_** point to somewhere in memory, but the area that was pointed to can no longer be accessed. Therefore we must not use this pointer again until new data is allocated using the pointer.

## References

1. http://www.learn-c.org/