
use peg = "peg"
use "files"
use "json"

primitive VellangStd
  fun str(): VFunction val =>
    VFunction.template({
    (s': Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val,
    {
    (s: Scope, args: VarList, ms: MetaScope) =>
      let distributed = s.clone()
      let fmt: Array[String] = []
      for arg in args.values() do
        fmt.push(arg.eval(distributed, ms.clone()).string())
      end
      Atom(" ".join(fmt.values()))
    }val)

  fun echo(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      let fmt: Array[String] = []
      for arg in args.values() do
        fmt.push(arg.eval(s, ms.clone()).string())
      end
      let printed = "\n".join(fmt.values()) + "\n"
      @printf(printed.cstring())
      Atom(consume printed)
      }val)

  fun sys(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      var res: I32 = 0
      let distributed = s.clone()
      for arg in args.values() do
        res = @system(arg.eval(distributed, ms.clone()).string().cstring())
        if res != 0 then
          break
        end
      end
      Atom(res.string())
    }val)

  fun run_script(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val,
    {
    (s: Scope, args: VarList, ms: MetaScope) =>
      var res: I32 = 0
      for arg in args.values() do
        // TODO change this madness
        res = @system(("velle script run " + arg.eval(s.clone(), ms.clone()).string()).cstring())
        if res != 0 then
          break
        end
      end
      Atom(res.string())
    }val)

  fun def_var(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let name  = args(0)?.eval(s, ms.clone()).string()
        let value = args(1)?
        s.update(consume name, value)
        Atom(true)
      else Atom(false) end
    }val)

  fun val_var(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let name = args(0)?.eval(s.clone(), ms.clone()).string()
        s(consume name)?.eval(s, ms)
      else Atom(Error("Value not found.")) end
    }val)

  fun defun(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let name  = args(0)?.eval(s.clone(), ms.clone()).string()
        let fun_args = args(1)?.eval(s.clone(), ms.clone()).string()
        let value = args(2)? as Executor val
        ms.functions.update(consume name, (consume fun_args, value))
        Atom(true)
      else Atom(false) end
    }val)

  fun custom_call(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let passed_scope = s.clone()
        let name = args(0)?.eval(s.clone(), ms.clone()).string()
        let fun_args = args.slice(1)
        let func = ms.functions(consume name)?
        let arg_names = func._1.split_by(" ")

        var i: USize = 0
        while true do
          try
            let key = arg_names(i)?
            let value = fun_args(i)?
            passed_scope(key) = value
            i = i + 1
          else break end
        end
        func._2.eval(passed_scope, ms.clone())
      else
        Atom(Error("Couldn't call the function"))
      end
    }val)

  fun call(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let passed_scope = s.clone()
        let name = args(0)?.eval(s.clone(), ms.clone()).string()
        let fun_args = args.slice(1)
        let func = ms.functions(consume name)?
        let arg_names = func._1.split_by(" ")

        var i: USize = 0
        while true do
          try
            let key = arg_names(i)?
            let value = fun_args(i)?
            passed_scope(key) = value
            i = i + 1
          else break end
        end
        func._2.eval(passed_scope, ms.clone())
      else
        Atom(Error("Couldn't call the function"))
      end
    }val)

  fun do_seq(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      let distributed = s.clone()
      let ms' = ms.clone()
      var ret = Atom(Error("No Arguments to do-seq"))
      for arg in args.values() do
        ret = arg.eval(distributed, ms')
      end
      ret
    }val)

  fun eq(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let v2 = args(1)?.eval(s.clone(), ms.clone()).value
        match args(0)?.eval(s.clone(), ms.clone()).value
        | let v: String => Atom(v == (v2 as String))
        | let v: F64    => Atom(v == (v2 as F64))
        | let v: Bool   => Atom(v == (v2 as Bool))
        | let v: Error val  => Atom(v)
        end
      else Atom(Error("Can't use eq on arguments")) end
    }val)

  fun is_error(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        args(0)?.eval(s.clone(), ms.clone()).value as Error val
        Atom(true)
      else Atom(false) end
    }val)

  fun if_stmt(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let cond = args(0)?.eval(s, ms)
        let outcome = cond.value as Bool
        if outcome then
          args(1)?.eval(s, ms)
        else
          args(3)?.eval(s, ms)
        end
      else Atom(Error("If statement failed")) end
    }val)

  fun match_case(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      var ret: Atom val = Atom(Error("No cases matched in a match-case"))
      try
        let compared = args(0)?.eval(s, ms).value
        var i: USize = 1
        while true do
          let value = args(i)?.eval(s.clone(), ms.clone()).value
          if match value
            | let v: String => v == (compared as String)
            | let v: Bool   => v == (compared as Bool)
            | let v: F64    => v == (compared as F64)
            | let v: Error val  => false
          end then
            ret = args(i+1)?.eval(s.clone(), ms.clone())
          end
          i = i + 2
        end
      end
      ret
    }val)

  fun config_read(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      let config_file = try File(
        FilePath(ms.env.root as AmbientAuth, "./.velle/config.json")?)
      else return Atom(Error("Couldn't read config")) end
      try
        let doc = JsonDoc .> parse(config_file.read_string(1_000_000_000))?
        let key = args(0)?.eval(s.clone(), ms.clone()).value as String
        Atom((doc.data as JsonObject).data(key)? as String)
      else Atom(Error("")) end
    }val)

  fun config_write(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      let config_file = try File(
        FilePath(ms.env.root as AmbientAuth, "./.velle/config.json")?)
      else return Atom(Error("Couldn't read config")) end
      try
        let doc = JsonDoc .> parse(config_file.read_string(1_000_000_000))?
        let key = args(0)?.eval(s.clone(), ms.clone()).value as String
        let value = args(1)?.eval(s.clone(), ms.clone()).value as String
        (doc.data as JsonObject).data(key) = value

        let contents = doc.string(where indent = "    ", pretty_print = true)
        config_file.seek_start(0)
        config_file.write(contents)
        config_file.set_length(contents.size())

        Atom(value)
      else Atom(Error("Couldn't write to config")) end
    }val)
