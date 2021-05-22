

use "cli"
use "files"
use "appdirs"

class Save

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


    try
      make_repository(get_unique_path(
        cmd', app_dirs.user_data_dir()?)
      , config_name)?
    else
      env.out.print("Couldn't create repository.")
    end

    try
      save_repo(get_unique_path(
        cmd', app_dirs.user_data_dir()?
      ) + "manivelle/" + config_name)?
    end

  fun get_unique_path(cmd': Command, repo_path: String): String =>
    let unique_end = try USize.from[ISize](
      repo_path.find(cmd'.fullname())?)
    else 0 end

    repo_path.trim(0, unique_end)


  fun make_repository(unique_path: String, name: String)? =>

    let root = Directory(
      FilePath(env.root as AmbientAuth, unique_path)?
    )?
    if not root.mkdir("manivelle") then
      error
    end

    let main_repo = Directory(
      FilePath(env.root as AmbientAuth, unique_path + "manivelle")?
    )?

    try main_repo .> open(name)? .> remove(name) end

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

  fun save_repo(repo_path: String)? =>
    let worker = CopyWorker(repo_path, ".", "",
      env.root as AmbientAuth, verbose)


class CopyWorker

  let auth: AmbientAuth
  let repo_name: String
  let start_path: String
  let base_dir: String
  let util: FileUtil

  let verbose: Bool

  new create(repo_name': String,
  current_dir': String,
  start_path': String,
  auth': AmbientAuth,
  verbose': Bool = false) =>

    auth = auth'
    repo_name  = repo_name'
    start_path = start_path'
    base_dir   = current_dir'
    util       = FileUtil(auth')
    verbose    = verbose'

    work()

  fun get_dirs(): (Directory val, Directory val)? =>
    let original = recover val
      Directory(FilePath(auth, base_dir  + "/" + start_path)?)? end
    let target   = recover val
      Directory(FilePath(auth, repo_name + "/" + start_path)?)? end
    (original, target)

  fun work() =>
    let directories = try get_dirs()?
    else return end

    for entry in try directories._1.entries()?.values() else return end do

      let info = try directories._1.infoat(entry)? else continue end
      if info.file then
        util.copy(entry, directories._1, directories._2)
        if verbose then
          @printf(("Copying " + start_path + entry + "..\n").cstring())
        end
      else
        CopyWorker(repo_name, base_dir, start_path + entry, auth, verbose)
      end
    end
