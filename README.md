
# Manivelle
Manivelle (or hand crank) is a tool for saving and loading your boilerplate. This includes files and folder structures that are always identical, but also scripts you run, and all sorts of magix.

## Installation
You can simply compile Manivelle using ponyc / corral and put it into your path.
Another option (not implemented yet) is to run this command.

``` shell
$ corral run -- ponyc && ./Manivelle install --as velle
```
This should install manivelle as `velle` on your system.

## Usage

You can find all you need with

``` shell
$ velle --help
usage: manivelle [<options>] <command> [<args> ...]

a tool for working with file systems and boilerplate.

Options:
   -h, --help=false       
   -V, --verbose=false    whether to log progress

Commands:
   help <command>        
   save <path> <name>    saves the current folder
   init                  inits manivelle script
```

