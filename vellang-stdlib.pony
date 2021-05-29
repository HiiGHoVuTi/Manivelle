
use peg = "peg"
use "files"
use "json"

primitive VellangStd
  fun str(): VFunction val =>
    VFunction.template({
    (s': Scope, ev: Evaluator val, args: VarList, env:Env) =>
      Executor(args, ev, env)
    }val,
    {
    (s: Scope, args: VarList, env: Env) =>
      let distributed = s.clone()
      let fmt: Array[String] = []
      for arg in args.values() do
        fmt.push(arg.eval(distributed).string())
      end
      Atom(" ".join(fmt.values()))
    }val)

  fun echo(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, env:Env) =>
      Executor(args, ev, env)
    }val, {
    (s: Scope, args: VarList, env: Env) =>
      let fmt: Array[String] = []
      for arg in args.values() do
        fmt.push(arg.eval(s).string())
      end
      let printed = "\n".join(fmt.values()) + "\n"
      @printf(printed.cstring())
      Atom(consume printed)
      }val)

  fun sys(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, env:Env) =>
      Executor(args, ev, env)
    }val, {
    (s: Scope, args: VarList, env: Env) =>
      var res: I32 = 0
      let distributed = s.clone()
      for arg in args.values() do
        res = @system(arg.eval(distributed).string().cstring())
        if res != 0 then
          break
        end
      end
      Atom(res.string())
    }val)

  fun run_script(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, env:Env) =>
      Executor(args, ev, env)
    }val,
    {
    (s: Scope, args: VarList, env: Env) =>
      var res: I32 = 0
      for arg in args.values() do
        // TODO change this madness
        res = @system(("velle script run " + arg.eval(s.clone()).string()).cstring())
        if res != 0 then
          break
        end
      end
      Atom(res.string())
    }val)

  fun def_var(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, env:Env) =>
      Executor(args, ev, env)
    }val, {
    (s: Scope, args: VarList, env: Env) =>
      try
        let name  = args(0)?.eval(s).string()
        let value = args(1)?
        s.update(consume name, value)
        Atom("0")
      else Atom("-1") end
    }val)

  fun val_var(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, env:Env) =>
      Executor(args, ev, env)
    }val, {
    (s: Scope, args: VarList, env: Env) =>
      try
        let name = args(0)?.eval(s.clone()).string()
        s(consume name)?.eval(s)
      else Atom("-1") end
    }val)

  fun do_seq(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, env:Env) =>
      Executor(args, ev, env)
    }val, {
    (s: Scope, args: VarList, env: Env) =>
      let distributed = s.clone()
      var ret = Atom(/* Nil */"")
      for arg in args.values() do
        ret = arg.eval(distributed)
      end
      ret
    }val)

  fun eq(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, env:Env) =>
      Executor(args, ev, env)
    }val, {
    (s: Scope, args: VarList, env: Env) =>
      try
        let v2 = args(1)?.eval(s.clone()).value
        match args(0)?.eval(s.clone()).value
        | let v: String => Atom(v == (v2 as String))
        | let v: F64    => Atom(v == (v2 as F64))
        | let v: Bool   => Atom(v == (v2 as Bool))
        end
      else Atom(/* Nil */"") end
    }val)

  fun if_stmt(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, env:Env) =>
      Executor(args, ev, env)
    }val, {
    (s: Scope, args: VarList, env: Env) =>
      try
        let cond = args(0)?.eval(s)
        let outcome = cond.value as Bool
        if outcome then
          args(1)?.eval(s)
        else
          args(3)?.eval(s)
        end
      else Atom(/* Nil */"") end
    }val)


  fun config_read(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, env:Env) =>
      Executor(args, ev, env)
    }val, {
    (s: Scope, args: VarList, env: Env) =>
      let config_file = try File(
        FilePath(env.root as AmbientAuth, "./.velle/config.json")?)
      else return Atom(/* Nil */"") end
      try
        let doc = JsonDoc .> parse(config_file.read_string(1_000_000_000))?
        let key = args(0)?.eval(s.clone()).value as String
        Atom((doc.data as JsonObject).data(key)? as String)
      else Atom(/* Nil */"") end
    }val)

  fun config_write(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, env:Env) =>
      Executor(args, ev, env)
    }val, {
    (s: Scope, args: VarList, env: Env) =>
      let config_file = try File(
        FilePath(env.root as AmbientAuth, "./.velle/config.json")?)
      else return Atom(/* Nil */"") end
      try
        let doc = JsonDoc .> parse(config_file.read_string(1_000_000_000))?
        let key = args(0)?.eval(s.clone()).value as String
        let value = args(1)?.eval(s.clone()).value as String
        (doc.data as JsonObject).data(key) = value

        let contents = doc.string(where indent = "    ", pretty_print = true)
        config_file.seek_start(0)
        config_file.write(contents)
        config_file.set_length(contents.size())

        Atom(value)
      else Atom(/* Nil */"") end
    }val)
