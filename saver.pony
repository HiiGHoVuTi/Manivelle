
use "cli"

class Save

  let env: Env
  let path_string: String
  let config_name: String

  new create(env': Env, cmd': Command) =>
    env = env'
    path_string = cmd'.arg("path").string()
    config_name = cmd'.arg("name").string()

    env.out.print(path_string + " / " + config_name)
