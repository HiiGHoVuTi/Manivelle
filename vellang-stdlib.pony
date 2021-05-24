
use peg = "peg"

use @_mkdir[I32](dir: Pointer[U8] tag) if windows
use @mkdir[I32](path: Pointer[U8] tag, mode: U32) if not windows

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
    None

  fun copy(args: Array[Variable]): Variable =>
    None

  fun input(args: Array[Variable]): Variable =>
    None

  fun bool_to_atom(v: Bool): String =>
    match v
    | true => ":true*"
    | false => ":false*"
    else "" end

  fun eq(args: Array[Variable]): Variable =>
    let a1 = try args(0)? as String
    else return try bool_to_atom((args(1)? as None) == None)
    else return bool_to_atom(false) end end

    let a2 = try args(1)? as String
    else return bool_to_atom(false) end

    bool_to_atom(a1 == a2)

  fun aeq(args: Array[Variable]): Variable =>
    eq(args)

  fun nnot(args: Array[Variable]): Variable =>
    let v = try args(0)? as String
    else return None end
    match v
    | ":true*" => ":false*"
    | ":false*" => ":true*"
    else None
    end

  fun anot(args: Array[Variable]): Variable =>
    let v = try args(0)? as String
    else return bool_to_atom(true) end
    match v
    | ":true*" => ":false*"
    | ":false*" => ":true*"
    else bool_to_atom(true)
    end
