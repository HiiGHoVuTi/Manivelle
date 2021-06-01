

use "cli"
use "files"
use "appdirs"

class Save

  let env: Env
  let path_string: String
  let config_name: String

  let ignored: Array[String]

  let verbose: Bool

  new create(env': Env, cmd': Command) =>
    env = env'
    path_string = cmd'.arg("path").string()
    config_name = cmd'.arg("name").string()
    verbose     = cmd'.option("verbose").bool()

    ignored = try

      let file = File(FilePath(
        env.root as AmbientAuth, path_string + "/" + ".velleignore")?)

      let out: Array[String] = []
      for line in file.lines() do out.push(line.clone()) end
      out

    else [] end

    let app_dirs = AppDirs(env.vars, cmd'.fullname())

    try
      make_repository(RepoManager.get_unique_path(
        cmd', app_dirs.user_data_dir()?)
      , config_name)?
    else
      env.out.print("Couldn't create repository.")
    end

    try
      save_repo(RepoManager.get_unique_path(
        cmd', app_dirs.user_data_dir()?
      ) + RepoManager.app_name + "/")?
    end

  fun make_repository(unique_path: String, name: String)? =>

    let root = Directory(
      FilePath(env.root as AmbientAuth, unique_path)?
    )?
    if not root.mkdir(RepoManager.app_name) then
      error
    end

    let main_repo = Directory(
      FilePath(env.root as AmbientAuth, unique_path + RepoManager.app_name)?
    )?

    try main_repo .> open(name)? .> remove(name) end
    try main_repo .> open_file(name + ".zip")? .> remove(name + ".zip") end

    if verbose then
      @printf("Creating the repo...\n\n".cstring())
    end
    if not main_repo.mkdir(name) then
      error
    end

  fun get_path(): FilePath? =>
    let path = try FilePath(env.root as AmbientAuth, path_string)?
    else
      env.out.print("Insufficient permissions")
      error
    end
    path

  fun get_dir(): Directory? =>
    let path = get_path()?
    let dir  = try Directory(path)?
    else
      env.out.print("Invalid path, not a directory")
      error
    end
    dir

  fun save_repo(app_path: String)? =>
    CopyWorker(app_path + config_name, path_string, "",
      env.root as AmbientAuth, verbose
    /*where ignored' = ignored*/)
    ZipWorker(app_path + config_name, app_path
    where filename' = config_name, remove_source' = true) .> zip()
