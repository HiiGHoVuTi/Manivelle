
# Manivelle
Manivelle (or hand crank) is a tool for saving and loading your boilerplate. This includes files and folder structures that are always identical, but also scripts you run, and all sorts of magix.

## Installation

To install manivelle, you'll need to use [Pony's](https://github.com/ponylang/ponyup) tools. Don't worry, they're great.

If you have them already, skip to the install command.

``` shell
$ sh -c "$(curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.sh)"

$ ponyup update ponyc release

$ ponyup update corral release
```

Then you can compile and install (as root) Manivelle !

``` shell
$ corral run -- ponyc

$ sudo ./Manivelle install --as velle --to /usr/bin 
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
   save <path> <name>    saves a given folder
   init                  inits manivelle scripts (not there yet)
   load <name>           loads a configuration
```

