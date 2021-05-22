
use "cli"

class val Config

  let desc: String =
  "a tool for working with file systems and boilerplate."
  let cmd: (Command | None)


  new val create(env: Env)? =>
    let cs = CommandSpec.parent("manivelle", desc, [

    ], [
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
  new create(env': Env) =>
    let cmd = match (try Config(env')? else return end).cmd
    | let c: Command => c
    | None =>
      env'.exitcode(-1)
    end
