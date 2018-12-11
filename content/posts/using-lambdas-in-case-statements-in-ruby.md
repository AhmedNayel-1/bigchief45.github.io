---
date: '2017-06-12'
tags:
- ruby
- programming
- exercism
title: Using Lambdas in Case Statements in Ruby
---

In a [previous post](http://aalvarez.me/blog/posts/using-objects-and-ranges-with-cases-in-ruby.html) I talked about how we could use Ruby ranges inside case statements. This was a very neat way of using case statements that would make our code more readable and less repetitive.

The other day I was trying to solve the [Bob Ruby exercise in Exercism](http://exercism.io/submissions/03c3c93f23b8420faff3107e2ad18286), and I came up with another very cool way to use case statements: with Lambdas.

## The Problem

The Bob problem is very simple. The program receives some input, and it returns some output based on the contents of the input. A strong indication for using a case statement. From the problem's README file:

```
Bob is a lackadaisical teenager. In conversation, his responses are very limited.

Bob answers 'Sure.' if you ask him a question.

He answers 'Whoa, chill out!' if you yell at him.

He says 'Fine. Be that way!' if you address him without actually saying anything.

He answers 'Whatever.' to anything else.
```

## Solutions

The test provided by Exercism indicates that we should create a `Bob` class with a `hey` class method that receives a remark. We could then use a case statement with this remark and evaluate if the remark is a question, yelling, or whatever else needs to be determined according to the instructions. We could create some class methods to determine each of these possibilities:

<!--more-->

```ruby
class Bob
  def self.hey(remark)
    case remark
    when nothing?(remark)
      'Fine. Be that way!'
    when yell?(remark)
      'Whoa, chill out!'
    when question?(remark)
      'Sure.'
    else
       'Whatever.'
    end
  end

  private

  def self.question?(remark)
  end

  def self.yell?(remark)
  end

  def self.nothing?(remark)
  end
end
```

A very typical case statement. However, notice the **redundancy** in using `remark` for the case statement, while also passing it to the helper methods we created. In my opinion, the `case` statement should allow the `when` statements to be able to work with what was assigned to `case`. But in the example above, that would not work.

### Enter Lambdas

So what we want to achieve is to remove the `remark` parameter from the methods, while also calling the methods without needing to pass the remark, because it's already being referenced in the `case` statement. Ruby **Lambdas** allows us to achieve this.

Because `when` statements can take Lambdas and call them automatically, we can redefine the helper methods to return a lambda. Each lambda will perform the necessary logic to determine if the remark is a question, a yell, or nothing.

```ruby
private

def self.question?
  -> (r) { r[-1] == '?' }
end

def self.yell?
  lambda do |r|
    r = r.delete('^A-Za-z')
    return false if r.empty?

    r.split('').all? { |c| /[[:upper:]]/.match(c) }
  end
end

def self.nothing?
  -> (r) { r.strip.size.zero? }
end
```

=> Use the new lambda literal syntax for single line body blocks. Use the lambda method for multi-line blocks. Source: [Rubocop Ruby style guide](https://github.com/bbatsov/ruby-style-guide#lambda-multi-line)

Notice that we have removed the `remark` parameter from the methods. The methods no longer take any arguments, this gives the methods more sense and meaning when defining them as "boolean" methods by appending the `?` prefix to the method name.

By making the methods return a lambda, the `when` statement will receive this lambda when calling the method, and will proceed to call the lambda by passing the object used in the `case` statement automatically. Pretty neat!

We can then re-write our case statement like this:

```ruby
  def self.hey(remark)
    case remark
    when nothing?
      'Fine. Be that way!'
    when yell?
      'Whoa, chill out!'
    when question?
      'Sure.'
    else
      'Whatever.'
    end
  end
```

Much better!

## References

1. [My solution to Bob](http://exercism.io/submissions/03c3c93f23b8420faff3107e2ad18286)