
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

        Vellang(env) .> parse(consume source) .> run()

      else
        env.out.print("Failed to run script: " + script)
      end
    end


class Vellang

  let parser : peg.Parser val
  let runtime: VellangRunner

  var parsed: (peg.AST | None) = None

  new create(env: Env) =>
    parser  = VellangParser()
    runtime = VellangRunner(env)

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

class Error is Stringable
  let message: String
  new val create(msg': String) =>
    message = msg'
  fun clone(): Error val =>
    Error(message.clone())
  fun string(): String iso^ =>
    message.clone()

type AtomValue is (String | F64 | Bool | Error val)
type Variable is (Executor val | Atom val)

type VarList is Array[Variable] val
type Scope is Map[String, Variable] ref

class MetaScope
  let env: Env
  let functions: Map[String, Executor val]ref
  new create(env': Env, functions': Map[String, Executor val]ref) =>
    env = env'
    functions = functions'
  fun clone(): MetaScope ref =>
    MetaScope(env, functions.clone())

type Applicator is {(Scope, Evaluator val, VarList, MetaScope): Variable}
type Evaluator is {(Scope, VarList, MetaScope): Atom val}

class Atom is Stringable
  let value: AtomValue
  new val create(v': AtomValue) =>
    value = v'
  fun eval(_: Scope, __: MetaScope): Atom val =>
    Atom(value)
  fun string(): String iso^ => value.string()

class Executor
  let inner: VarList
  let evaluator: Evaluator val
  new val create(inn': VarList, ev': Evaluator val) =>
    inner = inn'
    evaluator = ev'
  fun eval(scope: Scope, ms: MetaScope): Atom val =>
    evaluator(scope, inner, ms)

class VFunction
  let applicator: Applicator val
  let evaluator : Evaluator val

  new val template(app': Applicator val, ev': Evaluator val) =>
    applicator = app'
    evaluator = ev'

  new val from_template(f': VFunction val) =>
    applicator = f'.applicator
    evaluator  = f'.evaluator

  fun apply(inner: VarList, scope: Scope, ms: MetaScope): Variable =>
    applicator(scope, evaluator, inner, ms)


/* ======== */

class VellangRunner

  let env: Env


  fun get_functions(): Map[String, VFunction val]ref =>
  Map[String, VFunction val].create()
  .> update("def",          VellangStd.def_var())
  .> update("val",          VellangStd.val_var())
  .> update("string",       VellangStd.str()) .> update("s:", VellangStd.str())
  .> update("echo",         VellangStd.echo())
  .> update("sys",          VellangStd.sys())
  .> update("run-script",   VellangStd.run_script())
  .> update("config-read",  VellangStd.config_read())
  .> update("config-write", VellangStd.config_write())
  .> update("eq",           VellangStd.eq())
  .> update("is-error",     VellangStd.is_error())
  .> update("do-seq",       VellangStd.do_seq())
  .> update("if",           VellangStd.if_stmt())
  .> update("match-case",   VellangStd.match_case())

  new create(env': Env) => env = env'

  fun run(ast: peg.AST) =>
    let global = Scope.create()
    let global_meta = MetaScope(env, Map[String, Executor val])
    try
      let branches = ((ast.extract() as peg.AST).children(1)? as peg.AST).children
      for branch in branches.values() do
        make_variable(branch).eval(global, global_meta)
      end

    else
      @printf("Tree issue.\n".cstring())
    end

  fun get_op(children: Array[peg.ASTChild]val): VFunction val? =>
    // TODO not first-only ops
    let op_node = children(0)? as peg.Token
    try
      VFunction.from_template(
        get_functions()(op_node.string())?)
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
      op(args, Scope.create(), MetaScope(env, Map[String, Executor val]))
      else Atom(/* Nil */"") end
    | let tok: peg.Token =>
      eval_token(tok)
    | peg.NotPresent =>
      Atom(/* Nil */"")
    end
