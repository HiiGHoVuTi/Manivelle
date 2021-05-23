
use "cli"
use "files"
use "appdirs"

class Install

  let env: Env
  let path_string: String
  let config_name: String

  let verbose: Bool


  new create(env': Env, cmd': Command) =>
    env = env'
    path_string = cmd'.arg("path").string()
    config_name = cmd'.arg("name").string()
    verbose     = cmd'.option("verbose").bool()
    let util    = try FileUtil(env'.root as AmbientAuth)? else return end

    let app_dirs = AppDirs(env.vars, cmd'.fullname())

    let unique_path = try RepoManager.get_unique_path(
        cmd', app_dirs.user_config_dir()?)
    else
      env.out.print("Can't locate data folder.")
      return
    end

    env.out.print(unique_path)
