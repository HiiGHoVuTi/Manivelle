
use peg = "peg"
use "cli"
use "files"
use "collections"

class TreeUtils
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
      // TreeUtils.print_tree(ast)
      runtime.run(ast)
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

/* ======== TYPEEEES ========= */

type AtomValue is (String | F64)
type Variable is (Executor val | Atom val)

type VarList is Array[Variable] val
type Scope is Map[String, Variable] ref

type Applicator is {(Scope, Evaluator val, VarList): Variable}
type Evaluator is {(Scope, VarList): Atom val}


class Atom is Stringable
  let value: AtomValue
  new val create(v': AtomValue) =>
    value = v'
  fun eval(_: Scope): Atom val =>
    Atom(value)
  fun string(): String iso^ => value.string()

class Executor
  let inner: VarList
  let evaluator: Evaluator val
  new val create(inn': VarList, ev': Evaluator val) =>
    inner = inn'
    evaluator = ev'
  fun eval(scope: Scope): Atom val =>
    evaluator(scope, inner)

class VFunction
  let applicator: Applicator val
  let evaluator : Evaluator val

  new val template(app': Applicator val, ev': Evaluator val) =>
    applicator = app'
    evaluator = ev'

  new val from_template(f': VFunction val) =>
    applicator = f'.applicator
    evaluator  = f'.evaluator

  fun apply(inner: VarList, scope: Scope): Variable =>
    applicator(scope, evaluator, inner)


/* ======== */

class VellangRunner

  let functions: Map[String, VFunction val]val = recover functions.create()
  .> update("let",        VellangStd.let_var())
  .> update("val",        VellangStd.val_var())
  .> update("string",     VellangStd.str()) .> update("s:", VellangStd.str())
  .> update("echo",       VellangStd.echo())
  .> update("sys",        VellangStd.sys())
  .> update("run-script", VellangStd.run_script())
  .> update("do-seq",     VellangStd.do_seq())
  end

  new create() => None

  fun run(ast: peg.AST) =>
    let global = Scope.create()
    try
      let branches = ((ast.extract() as peg.AST).children(1)? as peg.AST).children
      for branch in branches.values() do
        make_variable(branch).eval(global)
      end

    else
      @printf("Tree issue.\n".cstring())
    end

  fun get_op(children: Array[peg.ASTChild]val): VFunction val? =>
    // TODO not first-only ops
    let op_node = children(0)? as peg.Token
    try
      VFunction.from_template(
        functions(op_node.string())?)
    else
      @printf(("Function \"" + op_node.string() + "\" not found.\n").cstring())
      error
    end

  fun eval_token(tok: peg.Token): Atom val =>
    let fmt = tok.string()
    Atom(consume fmt)

  fun make_variable(branch: peg.ASTChild): Variable =>
    match branch
    | let bloatree: peg.AST => try
      let tree = bloatree.children(1)? as peg.AST
      let op = get_op(tree.children)?
      let args: VarList = recover val
        let out: VarList ref = []
        for child in tree.children.slice(1).values() do
          out.push(make_variable(child))
        end
        out
      end
      op(args, Scope.create())
      else Atom(/* Nil */"") end
    | let tok: peg.Token =>
      eval_token(tok)
    | peg.NotPresent =>
      Atom(/* Nil */"")
    end
