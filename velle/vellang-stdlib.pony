
use peg = "peg"
use "files"
use "json"
use "itertools"

primitive VellangStd

  fun compare(v1: AtomValue, v2: AtomValue): Bool =>
    try
      match v1
      | let v: String => v == (v2 as String)
      | let v: Bool   => v == (v2 as Bool)
      | let v: F64    => (v - (v2 as F64)).abs() < 0.001
      | let v: VList val  => v == (v2 as VList val)
      | let v: Error val  => false
      end
    else false end

  fun apply_struct(v: Atom val, args: VarList, s: Scope, ms: MetaScope): Atom val =>
    match v.value
    | let l: VList val =>
      try
        let index = USize.from[F64](args(0)?.eval(s, ms).value as F64)
        try
          let iend = USize.from[F64](args(1)?.eval(s, ms).value as F64)
          Atom(l.slice(index, iend))
        else Atom(l(index)) end
      else v end
    else v end

  fun str(): VFunction val =>
    VFunction.template({
    (s': Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor("&", args, ev)
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

  fun err(): VFunction val =>
    VFunction.template({
    (s': Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor("error", args, ev)
    }val,
    {
    (s: Scope, args: VarList, ms: MetaScope) =>
      let distributed = s.clone()
      let fmt: Array[String] = []
      for arg in args.values() do
        fmt.push(arg.eval(distributed, ms.clone()).string())
      end
      Atom(Error(" ".join(fmt.values())))
    }val)

  fun vnot(): VFunction val =>
    VFunction.template({
    (s': Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor("not", args, ev)
    }val,
    {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let arg = args(0)?.eval(s.clone(), ms.clone()).value
        Atom(not (arg as Bool))
      else Atom(Error("Invalid argument to not")) end
    }val)


  fun float(): VFunction val =>
    VFunction.template({
    (s': Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor("f:", args, ev)
    }val,
    {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let arg = args(0)?.eval(s.clone(), ms.clone()).string()
        Atom(arg.f64()?)
      else Atom(Error("Invalid argument to Number")) end
    }val)

  fun add(): VFunction val =>
    VFunction.template({
    (s': Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor("+", args, ev)
    }val,
    {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let arg1 = args(0)?.eval(s.clone(), ms.clone()).string().f64()?
        let arg2 = args(1)?.eval(s.clone(), ms.clone()).string().f64()?
        Atom(arg1 + arg2)
      else Atom(Error("Invalid arguments to arithmetic operation")) end
    }val)

  fun sub(): VFunction val =>
    VFunction.template({
    (s': Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor("-",args, ev)
    }val,
    {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let arg1 = args(0)?.eval(s.clone(), ms.clone()).string().f64()?
        let arg2 = args(1)?.eval(s.clone(), ms.clone()).string().f64()?
        Atom(arg1 - arg2)
      else Atom(Error("Invalid arguments to arithmetic operation")) end
    }val)

  fun mul(): VFunction val =>
    VFunction.template({
    (s': Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor("*", args, ev)
    }val,
    {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let arg1 = args(0)?.eval(s.clone(), ms.clone()).string().f64()?
        let arg2 = args(1)?.eval(s.clone(), ms.clone()).string().f64()?
        Atom(arg1 * arg2)
      else Atom(Error("Invalid arguments to arithmetic operation")) end
    }val)

  fun div(): VFunction val =>
    VFunction.template({
    (s': Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor("/", args, ev)
    }val,
    {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let arg1 = args(0)?.eval(s.clone(), ms.clone()).string().f64()?
        let arg2 = args(1)?.eval(s.clone(), ms.clone()).string().f64()?
        Atom(arg1 / arg2)
      else Atom(Error("Invalid arguments to arithmetic operation")) end
    }val)


  fun echo(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor("echo", args, ev)
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

  fun dbg(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor("dbg", args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let target = args(0)?
        let depth  = try match args(1)?.eval(s, ms).value
        | let v: F64    => USize.from[F64](v)
        else error
        end else 1 end
        let fmt    = target.dbg_string(s, ms, 0, depth)
        Atom(consume fmt)
      else Atom(Error("Couldn't dbg")) end
    })

  fun sys(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor("sys", args, ev)
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
      Executor("run-script", args, ev)
    }val,
    {
    (s: Scope, args: VarList, ms: MetaScope) =>
      var res: I32 = 0
      for arg in args.values() do
        // TODO change this madness
        let name = arg.eval(s.clone(), ms.clone()).string()
        let file = try
          File(FilePath(ms.env.root as AmbientAuth, ".velle/" + consume name + ".vl")?)
        else return Atom(Error("Couldn't import file.")) end
        Vellang(ms.env) .> parse(file.read_string(1_000_000)) .> run(s.clone(), ms)
      end
      Atom(0)
    }val)

  fun def_var(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor("def", args, ev)
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
      Executor("val", args, ev)
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
      Executor("defun", args, ev)
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
      Executor("", args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let passed_scope = s.clone()
        let name = args(0)?.eval(s.clone(), ms.clone()).string()
        let fun_args = args.slice(1)
        let func = try ms.functions(name.clone())?
        else
          let fun_args_cloned = recover Array[Variable](fun_args.size()) end
          for v in fun_args.values() do fun_args_cloned.push(v) end
          return VellangStd.apply_struct(s(name.clone())?.eval(s, ms), consume fun_args_cloned, s, ms)
        end
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
      Executor("call", args, ev)
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
      Executor("do-seq", args, ev)
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
      Executor("eq", args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let v1 = args(0)?.eval(s.clone(), ms.clone()).value
        let v2 = args(1)?.eval(s.clone(), ms.clone()).value
        Atom(VellangStd.compare(v1, v2))
        else Atom(Error("Can't use eq on arguments")) end
    }val)

  fun is_error(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor("is-error", args, ev)
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
      Executor("if",args, ev)
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
      Executor("match-case",args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      var ret: Atom val = Atom(Error("No cases matched in a match-case"))
      try
        let compared = args(0)?.eval(s, ms).value
        var i: USize = 1
        while true do
          let value = args(i)?.eval(s.clone(), ms.clone()).value
          if VellangStd.compare(value, compared) then
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
      Executor("config-read", args, ev)
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
      Executor("config-write", args, ev)
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

  fun list(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor(":",args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      let out = recover Array[AtomValue](args.size()) end
      for arg in args.values() do
        out.push(arg.eval(s, ms).value)
      end
      Atom(VList(consume out))
    }val)

  fun cat(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor("&cat",args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      let out = recover Array[VList val](args.size()) end
      for arg in args.values() do
        try
          let v = arg.eval(s, ms).value as VList val
          out.push(v)
        end
      end
      Atom(VList.concat(consume out))
    }val)

  fun idx(): VFunction val =>
    VFunction.template({
    (s: Scope, ev: Evaluator val, args: VarList, ms: MetaScope) =>
      Executor("idx",args, ev)
    }val, {
    (s: Scope, args: VarList, ms: MetaScope) =>
      try
        let index = USize.from[F64](args(1)?.eval(s, ms).value as F64)
        let indexable = args(0)?.eval(s, ms).value as VList val
        Atom(indexable(index))
      else Atom(Error("Uh oh, can't find index")) end
    }val)
