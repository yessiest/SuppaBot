#Syntax:
Each addition has it's own syntax, specified in this documentation. Some of the features use other features to extend the flexibility (e.g. File manipulation uses stack for filename handling.)

##Stack
The stack can be called from anywhere on the tape, and it can hold virtually infinite amount of stored cell data. It is used mainly by Execution and File manipulation additions as a way to input complex strings of characters. The following tokens are added for stack manipulation:

1. "``P``" - pushes the value on the tape to the stack.
1. "``p``" - pops the value off the stack and replaces the value in the current cell with the popped value. if there are no more values to pop, returns 0.
1. "``d``" - drops the contents of the stack.
1. "``s``" - reverses the stack.

##File manipulation
As Brainfuck++ uses special characters that conflict with Extended brainfuck, this addition provides a way to manipulate files. In addition, it allows to use multiple files during the process of execution, effectively allowing to read or write to any file and switch between multiple files. The process of reading and writing adds an additional parameter - the file pointer. File pointer is set to 0 upon opening a new file or upon getting out of bounds of the document. The following tokens are added:

2. "``F``" - open the file with a name, specified by concatenating the character values in the stack. Allows only NTFS compatible characters. (sorry, fellow linux users, but it is a sacrifice i am willing to make.) If a file does not exist, a new one is created. File pointer is set to 0
2. "``f``" - write the character in the current cell to the position of the file pointer. Increment the pointer by 1.
2. "``R``" - read the character under the file pointer and increment the pointer by 1. If EOF is reached, file pointer gets reset to 1 and a value of 0 is written to the current cell.
2. "``r``" - increment the file pointer by 1 without reading or writing to the document. If EOF is reached, 0 is written to the current cell.

##Sleep (delay) functionality
The character in Alarm Clock Radio, used to represent the sleep operation, happens to represent the end of program character in Extended Brainfuck, once again, creating a conflict. The following functions allow a replacement for this feature, with some additional functionality.

3. "``z``" - sleep for the amount of seconds specified by the value in the current cell.
3. "``Z``" - same as "``z``", except in milliseconds

##Execution
A feature, implemented for the purpose of additional communication between scripts. WARNING - This feature is exceptionally dangerous, and should be supressed when presented via some sort of remote access. To supress it, simply append the following code:

```Lua
--Suppose we have an instance of exbin interpreter, called xf. prepend this before calling the "run" method.
xf.tokens["E"] = nil
xf.tokens["e"] = nil
--P.S. using this, any token can be supressed.
```
