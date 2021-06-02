
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

      CommandSpec.parent("script", "manivelle script utility", [

      ], [

        CommandSpec.leaf("init", "inits scripts folder", [

        ], [

        ])?

        CommandSpec.leaf("create", "creates scripts", [

        ], [

          ArgSpec.string_seq("names", "names of the scripts")

        ])?

        CommandSpec.leaf("run", "runs scripts", [

        ], [

          ArgSpec.string_seq("names", "names of the scripts")

        ])?

      ])?

      CommandSpec.leaf("save", "saves a given folder", [

      ], [

        ArgSpec.string("path", "path to save")
        ArgSpec.string("name", "name of the configuration")

      ])?

      CommandSpec.leaf("load", "loads a configuration", [

      ], [

        ArgSpec.string("name", "name of the configuration")

      ])?

      CommandSpec.leaf("pull", "pulls a config from github to your machine", [

        OptionSpec.string("as", "alias for the config"
        where default' = "", short' = 'a')

      ], [

        ArgSpec.string("name", "name of the repo (user/project)")

      ])?

      CommandSpec.parent("config", "the current configuration file", [

      ], [

        CommandSpec.leaf("show", "displays the config", [

        ], [

        ])?

        CommandSpec.leaf("set", "sets a configuration variable usable using scripts", [

        ], [

          ArgSpec.string("key",   "name of the key")
          ArgSpec.string("value", "name of the value")

        ])?

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
    | (RepoManager.app_name + "/pull") => Pull(env', cmd)
    | (RepoManager.app_name + "/install") => Install(env', cmd)
    | (RepoManager.app_name + "/script/init") => CreateScriptsFolder(env', cmd)
    | (RepoManager.app_name + "/script/create") => CreateScripts(env', cmd)
    | (RepoManager.app_name + "/script/run") => VellangLauncher(env', cmd)
    | (RepoManager.app_name + "/config/set") => ConfigManager(env', cmd) .> set()
    | (RepoManager.app_name + "/config/show") => ConfigManager(env', cmd) .> show()
    else
      env'.out.print(cmd.fullname())
    end

  fun @runtime_override_defaults(rto: RuntimeOptions) =>
    rto.ponynoblock = true
