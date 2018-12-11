---
date: '2017-07-19'
tags: [love2d, lua, game dev]
title: Getting Started With Love2D Basics
---

I recently started playing around with [Love2D](https://love2d.org/) for game development. Although I am completely new to Lua, so far it's been pretty fun and I really like it.

I created this post to write down the most important basic concepts that I have encountered so far, so that I can use as quick reference later.

## Setting Up a Basic IDE

So far I've been using Love2D in Windows. Initially I started using Sublime Text 2 as my editor, but then figured out how to make my Love2D development experience much better using [Atom](https://atom.io/) combined with Github for Windows.

In Atom there is a great package called [**love-ide**](https://github.com/rameshvarun/love-ide) which has many great tools and features for developming with Love.

![Love Atom IDE](/posts/getting-started-with-love2d-basics/love_ide.jpg)

Some of these features include Lua linting, autocomplete, and being able to run the Love application right from Atom.

Additionally, we will want to use Window's console for debugging. To do so, enable these options:

![Love in Windows](/posts/getting-started-with-love2d-basics/love_ide_windows.jpg)

## Working With Keyboard Keys

We can interact with user input through the keyboard by determining if a certain key has been pressed. This is done like this:

```lua
if love.keyboard.isDown("right") then
  -- ...
end
```

The [`love.keyboard.isDown`](https://love2d.org/wiki/love.keyboard.isDown) function receives a `KeyConstant` string argument to indicate which key we want to test for. The complete list can be found [here](https://love2d.org/wiki/KeyConstant). Here are some examples:

| Key string |    Description    |
|:----------:|:-----------------:|
| `space`	| Space key |
| `backspace` |	Backspace key |
| `down` | Down arrow key |

<!--more-->

## Movement

In a Love program, the Love function `love.update()` is called every *tick*, followed by the `love.draw()` function.

To make objects move in the canvas, we can simply update their coordinate values inside the `update()` function. Then the `draw()` function will re-draw with the new values:

```lua
function love.load()
  x = 0
end

function love.update(dt)
  x = x + 1
end

function love.draw()
  love.graphics.rectangle("fill", x, 100, 100, 20, 20)
end
```

Keep in mind that the `x` variable is **global** and can be accessed by all of the functions in the example above.

## Object Oriented Programming

Lua doesn't come with built-in support for Object Oriented Programming. However, there is a very good small library called [**middleclass**](https://github.com/kikito/middleclass) that allows us to easily create our own classes and design our games in a OOP fashion:

```lua
class = require 'lib/middleclass'

Player = class('Player')
function Player:initialize(x, y)
	self.x = x
	self.y = y

	self.speed = 10
	self.cooldown = 20 -- ticks

	self.bullets = {}
end
```

We can then create instances of our class like this:

```lua
function love.load()
	player = Player:new(0, 550)
end
```

## Working With Images

A nice way to work with images that belong to certain objects (using OOP with [middleclass](https://github.com/kikito/middleclass)), is to assign the image path to a static attribute of the class. For example:

```lua
Player = class('Player')
Player.static.image = love.graphics.newImage('img/player.png')
```

Then, we can draw the image in Love's `draw` function (assuming that we already have a `Player` instance):

```lua
function love.draw()
	-- Draw player
	love.graphics.draw(Player.static.image, player.x, player.y, 0, 1)
end
```

### Random Booleans

This is more of an issue about Lua rather than Love. Sometimes it is necessary to generate a random boolean value for a particular reason.

I found a simple way to achieve this:

```lua
print(math.random(1,2) == 2)
```

## Working With The Mouse

We can use the [`love.mousepressed()`](https://love2d.org/wiki/love.mousepressed) function to trigger an action when the mouse is pressed.

We can custom define what this function will do. However, after many attempts I think this can only be done inside `main.lua`:

```lua
-- main.lua

function love.mousepressed(x, y, button, istouch)

end
```

## References

I have been using these great resources for learning Lua and Love2D:

1. https://www.youtube.com/watch?v=FUiz1kL0QtI
2. https://www.youtube.com/watch?v=FeLljv5clnw
3. https://github.com/kikito/love-tile-tutorial