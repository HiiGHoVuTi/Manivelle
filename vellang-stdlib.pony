
use peg = "peg"

use @mkdirat[I32](at: I32, name: Pointer[U8] tag, mode: U32)

primitive VellangStd
  fun echo(args: Array[Variable]): Variable =>

    let fmt = String
    for arg in args.values() do
      match arg
      | let s: String => fmt.append(s + " ")
      // | None => @printf("bruh\n".cstring())
      end
    end

    @printf(fmt .> append("\n") . cstring())
    None

  fun string(args: Array[Variable]): Variable =>
    let fmt = String
    for arg in args.values() do
      match arg
      | "\\" => fmt.append(" ")
      | let s: String => fmt.append(s + " ")
      // | None => @printf("bruh\n".cstring())
      end
    end
    fmt.clone() .> trim_in_place(0, fmt.size()-1)

  fun system(args: Array[Variable]): Variable =>
    var broke = false
    for arg in args.values() do
      match arg
      | let s: String => if @system(s.cstring()) != 0 then
        broke = true
        break end
      end
    end
    broke.string()

  fun import(args: Array[Variable]): Variable =>
    let lang = Vellang
    for arg in args.values() do
      match arg
      // change that mess
      | let s: String => VellangStd.system(["velle script run " + s])
      end
    end
    None

  fun mkdir(args: Array[Variable]): Variable =>
    //TODO fix
    let fmt = String
    for arg in args.values() do
      match arg
      | let s: String => fmt.append(s + " ")
      // | None => @printf("bruh\n".cstring())
      end
    end
    @mkdirat(-1, fmt.cstring(), U32(0x1FF)).string()

  fun copy(args: Array[Variable]): Variable =>
    None
