
use "cli"
use "files"
use "appdirs"

class CreateScriptsFolder

  let env: Env

  let verbose: Bool

  new create(env': Env, cmd': Command) =>
    env = env'
    verbose = cmd'.option("verbose").bool()

    try
      Directory(FilePath(env'.root as AmbientAuth, ".")?)?
        .> mkdir(".velle") .> create_file(".velle/_init.vl")?
      if verbose then
        @printf("Created .velle/\n".cstring())
      end
    end


class CreateScripts

  let env: Env
  let filenames: ReadSeq[String]

  let verbose: Bool

  new create(env': Env, cmd': Command) =>
    env = env'
    verbose   = cmd'.option("verbose").bool()
    filenames = cmd'.arg("names").string_seq()

    try
      Directory(FilePath(env'.root as AmbientAuth, "./velle")?)?
    else
      CreateScriptsFolder(env', cmd')
    end

    try
      let dir = Directory(FilePath(env'.root as AmbientAuth, "./.velle")?)?
      for name in filenames.values() do
        let file = dir.create_file(name + ".vl")?
        if verbose then
          env.out.print("Creating " + name + ".vl..")
        end
      end
    end
