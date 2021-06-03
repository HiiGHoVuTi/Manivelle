
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
  let env: Env

  var parsed: (peg.AST | None) = None

  new create(env': Env) =>
    env = env'
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

  fun run(s: Scope = Scope, ms: (MetaScope | None) = None) =>
    match parsed
    | None => return
    | let ast: peg.AST =>
      // TreeUtils.print_tree(ast)
      try  runtime.run(ast, s, ms as MetaScope)
      else runtime.run(ast, s, MetaScope(env, FunctionScope)) end
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

type VCollection is (RecoveredFunction val | VList val)

class Error is Stringable
  let message: String
  new val create(msg': String) =>
    message = msg'
  fun clone(): Error val =>
    Error(message.clone())
  fun string(): String iso^ =>
    "(Error: \"" + message.clone() + "\")"

type AtomValue is (String | F64 | Bool | Error val | VCollection)
type Variable is (Executor val | Atom val)

type VarList is Array[Variable] val
type Scope is Map[String, Variable] ref
type FunctionScope is Map[String, (String, Executor val)]

class MetaScope
  let env: Env
  let functions: FunctionScope ref
  new create(env': Env, functions': FunctionScope ref) =>
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
  fun dbg_string(_: Scope, __: MetaScope, ___: USize, ____: USize)
    : String iso^ => string()

class Executor
  let name: String val
  let inner: VarList
  let evaluator: Evaluator val
  new val create(name': String, inn': VarList, ev': Evaluator val) =>
    name = name'
    inner = inn'
    evaluator = ev'
  fun eval(scope: Scope, ms: MetaScope): Atom val =>
    evaluator(scope, inner, ms)
  fun dbg_string(s: Scope, ms: MetaScope,
  depth: USize, desired_depth: USize): String iso^ =>
    if depth > desired_depth then
      eval(s, ms).string()
    else
      let out = String
        .> append("(" + name)
      for child in inner.values() do
        out.append(" " + child.dbg_string(s, ms, depth + 1, desired_depth))
      end
      out .> append(")")
      recover out.clone() end
    end

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
  .> update("var",          VellangStd.def_var())
  .> update("val",          VellangStd.val_var())
  .> update("defun",        VellangStd.defun())
  .> update("call",         VellangStd.call())
  .> update("recover",      VellangStd.vrecover())
  .> update("lambda",       VellangStd.lambda()) .> update("ld", VellangStd.lambda())
  .> update("string",       VellangStd.str()) .> update("s:", VellangStd.str()) .> update("&", VellangStd.str())
  .> update("error",        VellangStd.err())
  .> update("dbg",          VellangStd.dbg())
  .> update("number",       VellangStd.float()) .> update("f:", VellangStd.float())
  .> update("+",            VellangStd.add())
  .> update("-",            VellangStd.sub())
  .> update("*",            VellangStd.mul())
  .> update("/",            VellangStd.div())
  .> update("echo",         VellangStd.echo())
  .> update("sys",          VellangStd.sys())
  .> update("run-script",   VellangStd.run_script())
  .> update("config-read",  VellangStd.config_read())
  .> update("config-write", VellangStd.config_write())
  .> update("eq",           VellangStd.eq())
  .> update("not",          VellangStd.vnot())
  .> update("is-error",     VellangStd.is_error())
  .> update("do",           VellangStd.do_seq())
  .> update("if",           VellangStd.if_stmt())
  .> update("match-case",   VellangStd.match_case())
  .> update(":",            VellangStd.list()) .> update("list", VellangStd.list())
  .> update("&cat",         VellangStd.cat())
  .> update("idx",          VellangStd.idx())
  .> update("map",          VellangStd.map())
  .> update("filter",       VellangStd.filter())
  .> update("&join",        VellangStd.join())

  new create(env': Env) => env = env'

  fun run(ast: peg.AST, global: Scope, global_meta: MetaScope) =>
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
      error
    end

  fun eval_token(tok: peg.Token): Atom val =>
    let fmt = tok.string()
    try Atom(fmt.f64()?)
    else match fmt
    | "\\" => Atom(" ")
    | "\\\\" => Atom("\\")
    else Atom(consume fmt) end end

  fun make_variable(branch: peg.ASTChild): Variable =>
    match branch
    | let bloatree: peg.AST => try
      let tree = bloatree.children(1)? as peg.AST

      var op_from_std = true
      let op = try get_op(tree.children)?
      else op_from_std = false ; VellangStd.custom_call() end

      let args: VarList = recover val
        let out: VarList ref = []
        for child in tree.children.slice(
        if op_from_std then 1 else 0 end).values() do
          out.push(make_variable(child))
        end
        out
      end

      op(args, Scope.create(), MetaScope(env, FunctionScope))
      else Atom(Error("Couldn't find your function.")) end
    | let tok: peg.Token =>
      eval_token(tok)
    | peg.NotPresent =>
      Atom(Error("Empty"))
    end
