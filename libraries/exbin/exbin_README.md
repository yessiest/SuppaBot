#EXBIn - Experimental eXtended Brainfuck interpreter
EXBIn is an interpreter written in pure Lua v5.x Unlike LuaBrainFuck by prapin, this interprerter uses a virtual machine fully written in lua. It is compatible with Lua 5.2, LuaJIT and Lua5.3. Lua 5.1 might be compatible, although it wasn't tested yet.

##Usage
Upon being required, EXBIn returns a class of the interpreter, with methods ``new`` and ``run``. To create in instance, simply call the method ``new`` with its first argument being either a table containing serialized tokens or a string of tokens. To execute the code, call the ``run`` method of the newly created exbin interprerter object.

```Lua
exbin = require "exbin"
bf = exbin.new("++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>.") --create an instance of the interpreter
output, instruction_counter = bf.run() --run the interpreter, from start to end or breakpoint
print(output, instruction_counter)
```

The second argument is used to describe additional options.
Following options are accepted:
1. ``tapesize`` - the length of the tape to store values in. Default is 30000
1. ``cellsize`` - the size of the cell, represented by the formula 8^x. Default is 8
1. ``ext1``, ``ext2``,``ext3`` - Extended Brainfuck functionality. Each level is set to ``false`` by default.
1. ``experimental`` - experimental additions (see Experimental Additions). Default is ``false``
1. ``debug`` - enable debugging tokens. Default is ``false``
1. ``dump_char`` - the character, in the form of a string, at which a portion of tape is dumped. Default is ``"``
1. ``debug_char`` - the character which sets the debug flag. When debug flag is enabled, additional information will be appended to the output, like current position on the tape, current token, etc. Default is ``'``
1. ``dump_capacity`` - describes the amount of cells to be dumped when the dump instruction is called. Default is 30.

A word of warning: calling ``run`` on an instance twice is to be considered as undefined behaviour.

##Experimental Additions
As dilaects such as Alarm Clock Radio and Brainfuck++ conflict with Extended Brainfuck, these additions were implemented in order to replace some of the features as friendly to Extended Brainfuck. The following functions are implemented:

2. Stack manipulation (used as string input for File and Execution features)
2. File manipulation
2. Shell interface
2. Delay and sleep functionality

The following features are yet-to-be implemented:

3. Socket manipulation and networking
3. Basic sound playback
3. Procedures
3. Parallel processes

For a detailed documentation on the usage of these features, see Additional Syntax

##License
\#TODO: license the project
