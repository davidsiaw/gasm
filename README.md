gasm
----

gasm is an assembler generator. It takes two parameters:

```
gasm <assembly_name.gasm.yml> <program.assembly_name.gasm>
```

Example
-------

`assembly_name.gasm.yml` is a description file. For example a simple file looks like this:

```yml
# mycpu.gasm.yml
asm:
  instructions:
    load a1, <x>: 0011xxxx
    load <x>    : 0001xxxx
    nop         : 10000000
```

then you can write a gasm file

```
load a1, 1
nop
```

and it will generate a file that can be turned into binary using `bsm2`

```bash
$ bsm2 < ruby gasm.rb mycpu.gasm.yml simple_prog.mycpu.gasm > simple_prog.a.out
```

Documentation
-------------

The instruction hash is a key value pair of instruction pattern and resulting bits in little endian order. gasm will attempt to pattern match from top to bottom. If it finds no match it will throw a `unknown instruction` error.

The pattern is matched from left to right. If inside the pattern there are the three characters `<x>` where `x` can be any _single_ letter, the assembler will then check and see if the source has a number at that point. More about supported numbers later. The number is then assigned to that letter variable.

In the resulting bits side, you express the bits as a series of set bits and what the variable occupies. For example

`aa <x>: 1000xxxx` Means `x` will be truncated to 4 bits and written in the place `xxxx`. So if `x` is `0x80` in an instruction `aa 0x80` then the result bits are `10001000`

You can also have multiple variables

`ins <x>, <y>: 1000xxyy` in this case will have 2 bits for xx and 2 bits for yy

So if you go `ins 1,2` you will get `10000110`.

gasm will ignore any spaces and treat them like they are not there (so you can add as many spaces and tabs as you like to make it readable). It will also pad all bit patterns with zeros to the right side up to 8 bits, so all lines fit on byte boundaries.

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

Start lines with a `;` to write comments

TODO
----

- maybe clean up somehow the state machine into something more readable
- implement labels like `main:` and be able to use that name as a number referring to an offset (might need instruction to specify how big it is or infer)
- implement common directives like `.start` or `.data` or to maybe say how far down the file it should be written??
- maybe custom keywords for different sections ?
