
use peg = "peg"

primitive VellangStd
  fun str(): VFunction val =>
    VFunction.template({
    (s': Scope, ev: Evaluator val, args: VarList) =>
      Executor(args, ev)
    }val,
    {
    (s: Scope, args: VarList) =>
      let distributed = s.clone()
      let fmt: Array[String] = []
      for arg in args.values() do
        fmt.push(arg.eval(distributed).string())
      end
      Atom(" ".join(fmt.values()))
    }val)

  fun echo(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList) =>
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
    (s: Scope, ev: Evaluator val, args: VarList) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList) =>
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
    (s: Scope, ev: Evaluator val, args: VarList) =>
      Executor(args, ev)
    }val,
    {
    (s: Scope, args: VarList) =>
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

  fun let_var(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList) =>
      try
        let name  = args(0)?.eval(s).string()
        let value = args(1)?
        s.update(consume name, value)
        Atom("0")
      else Atom("-1") end
    }val)

  fun val_var(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList) =>
      try
        let name = args(0)?.eval(s.clone()).string()
        s(consume name)?.eval(s)
      else Atom("-1") end
    }val)

  fun do_seq(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList) =>
      let distributed = s.clone()
      var ret = Atom(/* Nil */"")
      for arg in args.values() do
        ret = arg.eval(distributed)
      end
      ret
    }val)

  fun eq(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList) =>
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
    (s: Scope, ev: Evaluator val, args: VarList) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList) =>
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
