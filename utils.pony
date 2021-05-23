
use "files"

actor FileUtil

  let auth: AmbientAuth

  new create(auth': AmbientAuth) =>
    auth = auth'

  be copy(name: String, dir1: Directory val, dir2: Directory val,
    other_name: String = "", callback: {(File)}val = {(a: File) => None}val
  ) =>

    let saved_name = if other_name == "" then name else other_name end

    let file2 = try dir2.create_file(saved_name)?  else return end

    let file1 = try dir1.open_file(name)?          else return end

    file2.write(file1.read(1_000_000_000))

    callback(consume file2)

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
          @printf(("Copying " + start_path + "/" + entry + "..\n").cstring())
        end
      else
        if directories._2.mkdir(entry) then
          CopyWorker(repo_name, base_dir, start_path + entry, auth, verbose)
        end
      end
    end
