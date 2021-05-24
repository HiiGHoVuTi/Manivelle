
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

  fun fast_copy() =>
    // TODO ignore files

    ifdef linux or bsd then
      @system(("cp -R " + base_dir + " " + repo_name).cstring())
    elseif windows then
      @system(("xcopy " + base_dir + " " + repo_name + "/E/H/C/I").cstring())
    else
      @printf("Not implemented yet.\n".cstring())
    end


class ZipWorker

  let path: String
  let target: String
  let remove_source: Bool
  let filename: String

  new create(path': String, target': String,
    remove_source': Bool = false, filename': String = "") =>

    path = path'
    remove_source = remove_source'
    target = target'
    filename = filename'

  fun zip() =>
    ifdef linux or bsd then
      @system((
      "pushd " + target + "\n" +
      "zip -r -qq " + filename + ".zip" + " " + filename + "\n" +
      "popd"
      ).cstring())
      if remove_source then
        @system(("rm -rf " + path).cstring())
      end
    elseif windows then
      @printf("Not implemented yet.\n".cstring())
    else
      @printf("Not implemented yet.\n".cstring())
    end

  fun uzip()? =>
    ifdef linux or bsd then
      if @system(("unzip -qq " + target + " -d " + path).cstring()) != 0 then
        error
      end
      @system(("mv " + filename + "/* ." + "&& rm -rf " + filename).cstring())
      if remove_source then
        @system(("rm -rf " + path).cstring())
      end
      @system("ls".cstring())
    elseif windows then
      @printf("Not implemented yet.\n".cstring())
    else
      @printf("Not implemented yet.\n".cstring())
    end
