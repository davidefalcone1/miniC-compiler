# miniC-compiler
This is a compiler for mini C, a language largely inspired by the C programming language, as you can imagine.

## Quick start
In order to build the project, you need Flex and Bison (>=v3.7.6) to be installed on your computer.\
At this point, you can build the project:
```
make compiler
```
You can compile a compatible source file, the original program will be translated in a pseudo-assembler language and printed on the standard output.
```
./compiler example_source.c
```
Optionally, you can dump the output in a file:
```
./compiler example_source.c > example_assembler.asm
```
A new file ```example_assembler.asm``` has been created: if you check it out, you can see that contains the translation of the original program in a pseudo-assembler language.\
Finally, you can execute the program via:
```
java -jar interpreter.jar example_assembler.asm
```

## Language specifications
- Functions do not exist: the entire program is in a single input file which
represents the main function.
- Variables of type int and double and one-dimensional arrays of those types can be declared. The variables
cannot be initialized in the declaration phase (e.g. an instruction like int a=0; is not supported).
- The array indexes can be variables or integer numbers but not complex expressions (e.g. correct assignment
instruction: a[2]=3*b[c]-a[3];; invalid assignment instruction: a[2+4]=0; or a[c+1]=2;).
- The language allows the use of a particular print instruction print(<variable>); that allows to print the value represented by the variable with name <variable> (e.g. print(a[2]); print the vector a value of index 2).
- The while and if have exactly the same syntax of the C language.

## Compiler specifications
The compiler supports error reporting/recovery and type checking.\
The scanner was developed with Flex and the interpreter with Bison, therefore the project is mainly written in C.
An unordered linked list is used as symbol table.

## The project
This is an academic project for the course "Formal languages and compilers" of the Politecnico di Torino.\
You can access further information on the project and the course in general at the following link: https://www.skenz.it/compilers/flex_bison
