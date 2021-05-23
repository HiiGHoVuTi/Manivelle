
use "cli"
use "files"
use "appdirs"

class Install

  let env: Env
  let dest: String
  let alias: String

  let verbose: Bool


  new create(env': Env, cmd': Command) =>
    env = env'
    dest        = cmd'.option("to").string()
    alias       = cmd'.option("as").string()
    verbose     = cmd'.option("verbose").bool()

    let util     = try FileUtil(env'.root as AmbientAuth)? else return end

    if verbose then
      env.out.print("Trying to save to " + dest)
      env.out.print("Make sure you are able to write to that directory...")
    end
    copy_source(util)

  fun get_dirs(): (Directory val, Directory val)? =>
    let auth = (env.root as AmbientAuth)

    let original = recover val
      Directory(FilePath(auth, ".")?)? end
    let target   = recover val
      Directory(FilePath(auth, dest)?)? end
    (original, target)

  fun copy_source(util: FileUtil) =>
    let folders = try get_dirs()? else return end

    let callback = {(f: File) => f.chmod(FileMode .> exec())}val

    util.copy("Manivelle", folders._1, folders._2
    where other_name = alias, callback = callback)

    util.copy("Manivelle.exe", folders._1, folders._2
    where other_name = alias, callback = callback)
