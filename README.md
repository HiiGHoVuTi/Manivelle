
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
   script                manivelle script utility
     create <names>        creates scripts
     run <names>           runs scripts
     init                  inits scripts folder
   help <command>        
   save <path> <name>    saves a given folder
   load <name>           loads a configuration
   install               installs manivelle in the repo directory
```

## Scripts

So maybe you want to spice up your configurations with scripts. Lucky for you, villang exists for you. Here's a quick rundown.

``` shell
$ velle script init -V
Created .velle/
$ velle script create my_script
```

These two commands will let you create the proper folder and scripts for velle. You'll also see a `_init.vl`, it is the default script. Vellang, or velle-lisp is a simple language to let you interact with the user's machine without worrying too much. Here are the implemented functions:

``` lisp
( ; a program always is enclosed in brackets

(echo Hello World !) ; if provided multiple Words, echo will join them with a space

(echo
    (string Hello)
    (string World !))
    
(sys
    (s: touch file.txt) ; string has the alias s:
    (s: echo "Hello world" > file.txt)) ; every argument is a single string that will be executed by the users' system
    
(import
    (string other-module)) ; runs another .vl file in the .velle folder

(alias string %) ; alias is a shy form of a macro, it aliases a function

(echo (% Hello World !))

)
```

Now you can run the scripts:

``` shell
$ velle script run _init
```

