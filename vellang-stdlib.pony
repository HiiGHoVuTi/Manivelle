
use peg = "peg"

primitive VellangStd
  fun echo(pass': Array[peg.ASTChild], args: Array[Variable]): Variable =>

    let fmt = String
    for arg in args.values() do
      match arg
      | let s: String => fmt.append(s + " ")
      // | None => @printf("bruh\n".cstring())
      end
    end

    @printf(fmt .> append("\n") . cstring())
    None

  fun string(pass': Array[peg.ASTChild], args: Array[Variable]): Variable =>
    let fmt = String
    for arg in args.values() do
      match arg
      | "\\" => fmt.append(" ")
      | let s: String => fmt.append(s + " ")
      // | None => @printf("bruh\n".cstring())
      end
    end
    fmt.clone() .> trim_in_place(0, fmt.size()-1)

  fun system(pass': Array[peg.ASTChild], args: Array[Variable]): Variable =>
    for arg in args.values() do
      match arg
      | let s: String => @system(s.cstring())
      end
    end
    None

  fun import(pass': Array[peg.ASTChild], args: Array[Variable]): Variable =>
    let lang = Vellang
    for arg in args.values() do
      match arg
      // change that mess
      | let s: String => VellangStd.system([], ["velle script run " + s])
      end
    end
    None
