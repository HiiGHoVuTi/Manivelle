
use "files"

actor FileUtil

  let auth: AmbientAuth

  new create(auth': AmbientAuth) =>
    auth = auth'

  be copy(name: String, dir1: Directory val, dir2: Directory val) =>

    let file2 = try dir2.create_file(name)? else return end

    let file1 = try dir1.open_file(name)?   else return end

    file2.write(file1.read(1_000_000_000))
