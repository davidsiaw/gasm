gasm
----

gasm is an assembler generator. It takes two parameters:

```
ruby gasm.rb <assembly_name.gasm.yml> <program.assembly_name.gasm>
```

You can also pipe a gasm file in via STDIN by going:

```
ruby gasm.rb <assembly_name.gasm.yml> -
```

Since the hyphen `-` signals that the input will come from standard input.

Example
-------

`assembly_name.gasm.yml` is a description file. For example a simple file looks like this:

```yml
# mycpu.gasm.yml
asm:
  instructions:
    load a1, <x>: 0011xxxx
    load <x>    : 0001xxxx
    nop         : '10000000' # yaml would misinterpret this as a number so its quoted
```

then you can write a gasm file:

```
// simple_prog.mycpu.gasm
load a1, 1
nop
```

This would be the output of `ruby gasm.rb mycpu.gasm.yml simple_prog.mycpu.gasm`:

```
load a1, 1
--
 d 49         
 h 0x31       
 o 0o061      
; <0011...1>

nop
--
 d 128        
 h 0x80       
 o 0o200      
; <10000000>
```

the output is a file that can be turned into binary using `bsm2`. https://github.com/davidsiaw/bsm2

```bash
$ bsm2 < ruby gasm.rb mycpu.gasm.yml simple_prog.mycpu.gasm > simple_prog.a.out
```

Documentation
-------------

The instruction hash is a key value pair of instruction pattern and resulting bits and a condition. gasm will attempt to pattern match from top to bottom. For each pattern that works it will check if the condition is met. If the pattern matches but the line has not been completely read, it will consider it a failure and move to the next pattern possible. If it finds no match it will throw a `unknown instruction` error.

The pattern is matched from left to right. If inside the pattern there are the three characters `<x>` where `x` can be any _single_ letter, the assembler will then check and see if the source has a number at that point. More about supported numbers later. The number is then assigned to that letter variable.

In the resulting bits side, you express the bits as a series of set bits and what the variable occupies. For example

`aa <x>: 1000xxxx` Means `x` will be truncated to 4 bits and written in the place `xxxx`. So if `x` is `0x80` in an instruction `aa 0x80` then the result bits are `10001000`

You can also have multiple variables

`ins <x>, <y>: 1000xxyy` in this case will have 2 bits for xx and 2 bits for yy

So if you go `ins 1,2` you will get `10000110`.

gasm will ignore any spaces and treat them like they are not there (so you can add as many spaces and tabs as you like to make it readable). It will also pad all bit patterns with zeros to the right side up to 8 bits, so all lines fit on byte boundaries.

You can also specify the byte ordering of the resulting instruction if you wish. gasm defaults to little endianness. It works on a per-parameter basis, so if you have an instruction like

`ldx <n>: 10101010 nnnnnnnn nnnnnnnn`

Then the result for `ldx $abcd` will be `10101010 11001101 10101011` or `ea cd ab`

You can specify this to be big endian by using big letters:

`ldx <n>: 10101010 NNNNNNNN NNNNNNNN`

Then the result for `ldx $abcd` will be `ea ab cd`

You can make the bit pattern on the right side as long as you want but it will always be padded to 8bits. Because of this you have the option of generating instructions that are of different widths, if you so choose.

You can try the included example to get a quick feel for how the program works by running:

```
ruby gasm.rb simple.gasm.yml example.simple.gasm 
```

## Numbers

Supported number formats are:

- decimal: `123`
- hexadecimal: `0xab` or `$af`
- binary: `0b00010010` or `%00010110`

## Comments

Start lines with a `//` to write comments.

```
// this is a comment
bit $abcd
```

Comments can be seen in the output. The result of the above is

```
// this is a comment
bit $abcd
--
 d 44         205        171        
 h 0x2c       0xcd       0xab       
 o 0o054      0o315      0o253      
; <00101100> <11001101> <10101011>
```

gasm also regards any double-slashes after valid statements to be the start of comments, and will ignore it for parsing

```
bit $abcd // things
```

will result in

```
bit $abcd // things
--
 d 44         205        171        
 h 0x2c       0xcd       0xab       
 o 0o054      0o315      0o253      
; <00101100> <11001101> <10101011>
```


Philosophy
-----------

When run with stdin mode you can see that it basically expands a file with a list of assembly instructions into a list of their bit representations.

gasm does not have directives or anything, but it could be used by a higher level program that would accept directives, and offset numbers and then make use of gasm to do the low level transformation of instructions to bytes.

TODO
----

- maybe clean up somehow the state machine into something more readable
- maybe custom keywords for different sections ?
