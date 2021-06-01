
use "cli"
use "files"
use "json"

class ConfigManager

  let env: Env
  let key: String
  let value: String

  let verbose: Bool

  new create(env': Env, cmd': Command) =>
    env = env'
    key   = cmd'.arg("key").string()
    value = cmd'.arg("value").string()
    verbose = cmd'.option("verbose").bool()

  fun set() =>
    let config_file = try File(
      FilePath(env.root as AmbientAuth, "./.velle/config.json")?)
    else return end
    try
      let doc = JsonDoc .> parse(config_file.read_string(1_000_000_000))?
      (doc.data as JsonObject).data(key) = value

      let contents = doc.string(where indent = "    ", pretty_print = true)
      config_file.seek_start(0)
      config_file.write(contents)
      config_file.set_length(contents.size())
    else return end

  fun show() =>
    let config_file = try File(
      FilePath(env.root as AmbientAuth, "./.velle/config.json")?)
    else return end
    try
      let doc = JsonDoc .> parse(config_file.read_string(1_000_000_000))?

      let contents = doc.string(where indent = "   ", pretty_print = true)
      env.out.print(contents)
    end
