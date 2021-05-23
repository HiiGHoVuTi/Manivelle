
use "cli"

use @printf[I32](fmt: Pointer[U8] tag, ...)
use @system[I32](fmt: Pointer[U8] tag)

class val Config

  let desc: String =
  "a tool for working with file systems and boilerplate."
  let cmd: (Command | None)

  new val create(env: Env)? =>
    let cs = CommandSpec.parent("manivelle", desc, [

    OptionSpec.bool("verbose", "whether to log progress"
    where default' = false, short' = 'V')

    ], [

      CommandSpec.leaf("install", "installs manivelle in the repo directory", [

        OptionSpec.string("as", "the name manivelle will go by"
        where default' = "velle", short' = 'a')

        OptionSpec.string("to", "the folder to install in (prefer PATH folders)"
        where default' = "/usr/bin")

      ], [

      ])?

      CommandSpec.leaf("init", "inits manivelle scripts (not there yet)", [], [])?

      CommandSpec.leaf("save", "saves a given folder", [

      ], [
        ArgSpec.string("path", "path to save")
        ArgSpec.string("name", "name of the configuration")
      ])?

      CommandSpec.leaf("load", "loads a configuration", [

      ], [
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
    | (RepoManager.app_name + "/save") => Save(env', cmd)
    | (RepoManager.app_name + "/load") => Load(env', cmd)
    | (RepoManager.app_name + "/install") => Install(env', cmd)
    else
      env'.out.print(cmd.fullname())
    end
