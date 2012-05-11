Drop
====

A simple block-dropping game in Lua

Requirements:
-------------

- Lua 5.1
- An ANSI-compatible console (like xterm or Terminal.app)

How to play:
------------

Right now there's no good interface. This is because this is just game logic and will eventually be ported to iOS.

To start the game, start a Lua REPL, require `drop`, then make an instance of it:

```lua
require 'drop'
d = drop.new()
print(d)
```

You can take a turn by choosing which column you want to drop the next piece into. Taking a turn then returns the next board state:

```lua
print(d(3))
```

Columns are numbered from 0 on the left to 7 on the right. The color piece you will drop is the one on the left of the queue.

Rules of the game:
------------------

You have a queue of pieces, each with a color. Each turn you get the next piece from the queue and drop it into a column.

If a dropped piece lands on a piece of the same color, that piece (and all the ones connected to it of that color) disappear. Pieces fall to the bottom to fill the gaps left.

After your queue of pieces ends, a fresh row is pushed on to the bottom, and the queue is refilled.

End of the game:
----------------

If the board completely fills on your turn, you lose. Also, if you have any pieces in the top row when the queue empties (so that pushing a row on to the bottom would push them off the board) then you lose.

Currently there is no way to win. I'm considering making the goal be "clear the board". What do you think?