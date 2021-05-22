
use "cli"

use @printf[I32](fmt: Pointer[U8] tag, ...)

class val Config

  let desc: String =
  "a tool for working with file systems and boilerplate."
  let cmd: (Command | None)

  new val create(env: Env)? =>
    let cs = CommandSpec.parent("manivelle", desc, [
    OptionSpec.bool("verbose", "whether to log progress"
    where default' = false, short' = 'V')
    ], [

      CommandSpec.leaf("init", "inits manivelle scripts", [], [])?

      CommandSpec.leaf("save", "saves the current folder", [

      ], [
        ArgSpec.string("path", "path to save")
        ArgSpec.string("name", "name of the configuration")
      ])?

    ])? .> add_help()?

    cmd = match CommandParser(cs).parse(env.args, env.vars)
    | let c: Command => c
    | let ch: CommandHelp =>
      ch.print_help(env.out)
      None
    | let se: SyntaxError =>
      env.out.print(se.string())
      None
    end


actor Main

  let _app_name: String = "manivelle"

  new create(env': Env) =>

    let cnf = try Config(env')?
      else env'.out.print("Internal error") ; return end
    let cmd = match cnf.cmd
    | let c: Command => c
    | None =>
      env'.exitcode(-1)
      return
    end

    match cmd.fullname()
    | (_app_name + "/save") => Save(env', cmd)
    end
