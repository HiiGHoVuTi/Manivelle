
use "cli"
use "files"
use "appdirs"

class Pull

  let env: Env
  let dest: String
  var alias: String

  let verbose: Bool


  new create(env': Env, cmd': Command) =>
    env = env'
    dest        = cmd'.arg("name").string()
    alias       = if cmd'.option("as").string() != ""
      then cmd'.option("as").string()
      else try dest.split_by("/")(1)?
      else dest end end
    verbose     = cmd'.option("verbose").bool()

    let app_dirs = AppDirs(env.vars, cmd'.fullname())

    let unique_path = try RepoManager.get_unique_path(
        cmd', app_dirs.user_data_dir()?)
    else
      env.out.print("Can't locate data folder.")
      return
    end

    clone(unique_path)


  fun make_local(unique_path: String)? =>
    Directory(FilePath(
      env.root as AmbientAuth, unique_path + RepoManager.app_name)?)?
    .> mkdir(alias)
    .> remove(alias + ".zip")

  fun clone(unique_path: String) =>
    try make_local(unique_path)? else return end

    let target_path = recover box
      String
      .> append(unique_path)
      .> append(RepoManager.app_name) .> append("/")
      .> append(alias)
    end
    let url = recover box
      String
      .> append("https://github.com/")
      .> append(dest)
      .> append(".git")
    end

    @system(("git clone " + url + " " + target_path).cstring())

    ZipWorker(recover val
      String
        .> append(unique_path)
        .> append(RepoManager.app_name) .> append("/")
        .> append(alias)
      end, unique_path + RepoManager.app_name
    where filename' = alias, remove_source' = true) .> zip()
