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
    load a1, <x>: <0011xxxx>
    load <x>    : <0001xxxx>
    nop         : <10000000>
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

TODO
----

- implement comments
- maybe clean up somehow the state machine into something more readable
- implement labels like `main:` and be able to use that name as a number referring to an offset (might need instruction to specify how big it is or infer)
- implement common directives like `.start` or `.data` or to maybe say how far down the file it should be written??
- maybe custom keywords for different sections ?
