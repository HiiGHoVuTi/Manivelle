
use "cli"
use "files"
use "appdirs"

class Load

  let env: Env
  let path_string: String
  let config_name: String

  let verbose: Bool

  new create(env': Env, cmd': Command) =>
    env = env'
    path_string = cmd'.arg("path").string()
    config_name = cmd'.arg("name").string()
    verbose     = cmd'.option("verbose").bool()

    let app_dirs = AppDirs(env.vars, cmd'.fullname())

    let unique_path = try RepoManager.get_unique_path(
        cmd', app_dirs.user_data_dir()?)
    else
      env.out.print("Can't locate data folder.")
      return
    end

    try
      Directory(FilePath(env.root as AmbientAuth,
        unique_path + RepoManager.app_name + "/" + config_name)?)?
    else
      env.out.print("Couldn't find the repository \"" + config_name + "\"")
      return
    end

    try load_repo(unique_path + RepoManager.app_name + "/" + config_name)?
    else
      env.out.print("Couldn't load the repository.")
    end

    // Run _init.vl

  fun load_repo(repo_path: String)? =>
    let worker = CopyWorker(".", repo_path, "",
      env.root as AmbientAuth, verbose)
