---
date: '2017-04-10'
tags:
- haml
- ace
- open source
- javascript
- cloud9
title: Reworking Ace's HAML Syntax Highlighting
---

[Ace](https://github.com/ajaxorg/ace) is a great web text editor and the default editor for [Cloud 9 IDE](https://c9.io). I have been using it for many years without any complaints at all. However I was not very satisfied with the HAML syntax highlighting, which seemed to have some problems caused by indentation when highlighting some tokens. Additionally, it didn't support correct highlighting of some HAML stuff such as HAML comments (which begin with `-#`) or block comments.

This is how Ace's HAML syntax highlighting issues look like:

![HAML Highlighting Issues](/posts/reworking-ace-s-haml-syntax-highlighting/haml_bad_highlighting.jpg)

I proceeded to study Ace's logic for syntax highlighting. It consists basically on a lexer that reads the input through different regular expressions and proceeds to different stages depending on the regular expression caught. Basically, a [state machine](https://en.wikipedia.org/wiki/Finite-state_machine). The source where this happens is found in [`lib/ace/mode/haml_highlight_rules.js`](https://github.com/ajaxorg/ace/blob/master/lib/ace/mode/haml_highlight_rules.js)

## Defining States

A few states have to be defined to represent where the lexer currently "stands" in regards to the code. For example, entering a multi-block comment could represent entering a new state, since everything parsed in this state would belong to this block comment until the block ends, this will also mean another change of state.

In Ace, all syntax highlighting lexers must begin with a `start` state. From this state we can switch to other defined states. The example below shows how we begin from the `start` state and can jump to a comment block state when the code matches a regular expression that represents this:

```javascript
this.$rules = {
    "start": [
        {
            token: "comment.block", // multiline HTML comment
            regex: /^\/$/,
            next: "comment"
        },
        {
            token: "comment.block", // multiline HAML comment
            regex: /^\-#$/,
            next: "comment"
},

/* ... */
```

Notice that we define 2 different comment types, since HAML [supports](http://haml.info/docs/yardoc/file.REFERENCE.html) HAML (not rendered in HTML) and HTML (rendered in HTML) comments. Both of these different regular expressions will make the lexer parse them as `comment.block` **tokens**, and will also make the lexer jump to a `comment` state, denoted by the `next` keyword.

<!--more-->

## Reworking The Syntax Highlighting

Reworking this syntax highlighting required fixing some mistakes in some of the existing regular expressions. Also there were not any states for comments, so I decided to add them as well. The complete details of my rework can be seen in [my pull request](https://github.com/ajaxorg/ace/pull/3251).

This is how the highlighting looks after my pull request was merged:

![HAML correct highlighting](/posts/reworking-ace-s-haml-syntax-highlighting/haml_good_highlighting.jpg)

## Future Work

There are still some improvements that can be made and hopefully I get time to address. Particularly the way indentation is handled by the lexer. Currently, this is handled purely by regular expressions, but it would be better to have a state for tokens that are currently indented. Also maybe make use of `push` and `pop` keywords for handling states. The [YAML syntax highlighting](https://github.com/ajaxorg/ace/blob/master/lib/ace/mode/yaml_highlight_rules.js#L74) was mentioned as reference to improve indentation detection.