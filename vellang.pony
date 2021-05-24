
use peg = "peg"
use "cli"
use "files"
use "collections"

class VellangLauncher

  let env: Env

  new create(env': Env, cmd': Command) =>
    env = env'
    let auth = try env.root as AmbientAuth else return end

    for script in cmd'.arg("names").string_seq().values() do
      try
        let file   = File(FilePath(
          auth, ".velle/" + script + ".vl"
        )?)
        let source = file.read_string(1_000_000)

        Vellang .> parse(consume source) .> run()

      else
        env.out.print("Failed to run script: " + script)
      end
    end


class Vellang

  let parser : peg.Parser val
  let runtime: VellangRunner

  var parsed: (peg.AST | None) = None

  new create() =>
    parser  = VellangParser()
    runtime = VellangRunner

  fun ref parse(source: String) =>
    let res =  parser.parse(peg.Source.from_string(source))._2
    parsed = match res
    | let ast: peg.AST => ast
    | let tok: peg.Token =>
      None
    | peg.Skipped =>
      None
    | peg.Lex =>
      None
    | peg.NotPresent =>
      None
    | let p: peg.Parser =>
      @printf(("Parser Error: " + p.error_msg() + "\n").cstring())
      None
    end

  fun run() =>
    match parsed
    | None => return
    | let ast: peg.AST =>
      // print_tree(ast)
      runtime.run(ast)
    end

  fun print_tree(ast: peg.AST, indent': String="") =>
    for child in ast.children.values() do
      match child
      | let tree: peg.AST   =>
        @printf((indent' + "- " + ast.label().text() + "\n").cstring())
        print_tree(tree where indent' = indent' + "  ")
      | let tok : peg.Token =>
        if tok.label().text() == "" then continue end
        @printf((indent' + "- " + tok.label().text() + ": " + tok.string() + "\n").cstring())
      | peg.NotPresent => None
      end
    end

primitive VellangParser
  fun apply(): peg.Parser val =>
    recover

      let whitespace = (peg.L(" ") / peg.L("\t") / peg.L("\r") / peg.L("\n")).many1()
      let comment = peg.L(";") * (peg.Unicode *
        not whitespace).many()

      let paren = peg.L("(") / peg.L(")")
      let word = (not paren *
        not whitespace * peg.Unicode).many1()
        .term(VWord)

      let value = peg.Forward
      value() = (peg.L("(") *
        (word / value).many()
        .node(VTerms)
      * peg.L(")"))
      .node(VExpr)

      value.many1().hide((comment / whitespace).many())
    end

primitive VWord   is peg.Label fun text(): String => "Word"
primitive VExpr   is peg.Label fun text(): String => "Expr"
primitive VTerms  is peg.Label fun text(): String => "Terms"

type Variable is (String | None)
type CollapsedFunction is {(Array[Variable]): Variable}
type CollapsedLazyFunction is {(Array[peg.ASTChild]): Variable}

actor VellangRunner

  let default: CollapsedFunction box = {(a: Array[Variable]) => None}box

  let std_lib: Map[String, CollapsedFunction box] = std_lib.create()
    .> update("sys",        VellangStd~system())
    .> update("run-script", VellangStd~import())
    .> update("echo",       VellangStd~echo())
    .> update("string",     VellangStd~string()) .> update("s:", VellangStd~string())
    .> update("copy",       VellangStd~copy())
    .> update("mkdir",      VellangStd~mkdir())

    .> update("alias", default)
    .> update("let", default)

  let variables: Map[String, Variable] = variables.create()

  new create() => None

  fun get_expr(ast: peg.AST): (peg.AST | None) =>
    try match ast.children(1)?
    | let tree: peg.AST => tree
    else None
    end else
      @printf("wrong dimensions\n".cstring())
      None
    end

  fun get_op(ast: peg.AST): CollapsedFunction box =>

    match ast.extract()
    | let tree: peg.AST =>
      @printf("Not Implemented.".cstring())
      return default
    | let tok: peg.Token =>
      try
        return std_lib(tok.string())?
      else
        if tok.string() != "(" then
        @printf(("Function \"" + tok.string() + "\" isn't defined\n").cstring())
      end end
    end
    default

  be run(ast: peg.AST) =>
    // do not question the block of code
    let main_expr = match try get_expr(
    match ast.children(0)?
    | let tree: peg.AST => tree
    else return end
    ) else return end
    | None => return
    | let tree: peg.AST => tree
    end

    do_seq(main_expr)

  fun ref do_seq(ast: peg.AST) =>
    for term in ast.children.values() do
      match term
      | let tree: peg.AST   => eval_sync(tree)
      | let tok : peg.Token => evaluate_single_identifier(tok)
      end
    end

  fun evaluate_single_identifier(tok: peg.Token): Variable =>
    match tok.string()
    | "(" => None
    | ")" => None
    | let s: String =>
      s
    end

  // refactor for lazy
  fun ref eval_sync(ast: peg.AST): Variable =>

    let expr = match get_expr(ast)
    | let tree: peg.AST => tree
    else return end

    let meta = eval_meta(expr, eval_args(expr.children.slice(1)))

    try meta as String else
      let op = get_op(expr)
      op(eval_args(expr.children.slice(1)))
    end

  fun ref eval_args(args: Array[peg.ASTChild]): Array[Variable] =>
    let out = Array[Variable](args.size())
    for arg in args.values() do
      out.push(
      match arg
      | let tree: peg.AST   => eval_sync(tree)
      | let tok : peg.Token => evaluate_single_identifier(tok)
      else
        None
      end
      )
    end
    out

  fun ref eval_meta(ast: peg.AST, args: Array[Variable]): Variable =>
    match ast.extract()
    | let tree: peg.AST =>
      None
    | let tok: peg.Token =>
      match tok.string()
      | "alias" => try

        let orig = try args(0)? as String else return end
        let targ = try args(1)? as String else return end

        let cmd = std_lib(orig)?
        std_lib.update(targ, cmd)
        targ
        end
      | "let" =>
        let name = try args(0)? as String else return end
        let value = try args(1)? else return end
        variables.update(name, value)
        value
      | "val" =>
        let name = try args(0)? as String else return end
        try variables(name)?
        else None end
      end
    else None end
