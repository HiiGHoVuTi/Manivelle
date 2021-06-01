
use "cli"
use "files"
use "appdirs"


class RepoManager

  let app_name: String = "manivelle"

  new create() => None

  fun get_unique_path(cmd': Command, repo_path: String): String =>
    let unique_end = try USize.from[ISize](
      repo_path.find(cmd'.fullname())?)
    else 0 end

    repo_path.trim(0, unique_end)
