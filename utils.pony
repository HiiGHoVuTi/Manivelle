
use "files"

actor FileUtil

  let auth: AmbientAuth

  new create(auth': AmbientAuth) =>
    auth = auth'

  be copy(name: String, dir1: Directory val, dir2: Directory val,
    other_name: String = "", callback: {(File)}val = {(a: File) => a.dispose()}val
  ) =>

    let saved_name = if other_name == "" then name else other_name end

    let file2 = try dir2.create_file(saved_name)?  else return end

    let file1 = try dir1.open_file(name)?          else return end

    file2.write(file1.read(file1.size()))
    file1.dispose()

    callback(consume file2)

class CopyWorker

  let auth: AmbientAuth
  let repo_name: String
  let start_path: String
  let base_dir: String

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
    verbose    = verbose'

    fast_copy()

  fun get_dirs(): (Directory val, Directory val)? =>
    let original = recover val
      Directory(FilePath(auth, base_dir + start_path)?)? end
    let target   = recover val
      Directory(FilePath(auth, repo_name + start_path)?)? end
    (original, target)

  fun fast_copy() =>
    ifdef linux or bsd then
      @system(("cp -R " + base_dir + " " + repo_name).cstring())
    elseif windows then
      @system(("xcopy " + base_dir + " " + repo_name + "/E/H/C/I").cstring())
    else
      @printf("Not implemented yet.\n".cstring())
    end
