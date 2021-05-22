"""
# AppDirs

Library for detecting platform specific user directories e.g. for data, config, cache, logs.

Most stuff is copied from the python library [appdirs](https://github.com/ActiveState/appdirs) from ActiveState.
"""
use "files"
use "cli" // for EnvVars
use "itertools"
use "collections"

primitive Paths
  fun join(paths: ReadSeq[String]): String =>
    Iter[String](paths.values())
      .fold[String]("", {(acc, cur) => Path.join(acc, cur)})

type _Maybe[T] is (T | None)

primitive _Opt
  fun get[T](s: _Maybe[T], or_else: T): T =>
    match consume s
    | let value: T => consume value
    | None => consume or_else
    end

class AppDirs
  let _home: _Maybe[String]
  let _env_vars: Map[String, String] val
  let _app_name: String
  let _app_author: _Maybe[String]
  let _app_version: _Maybe[String]
  let _roaming: Bool
  let _osx_as_unix: Bool

  new create(
    env_vars: _Maybe[Array[String] box],
    app_name: String,
    app_author: _Maybe[String] = None,
    app_version: _Maybe[String] = None,
    roaming: Bool = false,
    osx_as_unix: Bool = false)
  =>
    """
    An AppDirs instance derives the platform specific directories
    from the process environment variables.
    It will return appdirs for the user of the current process.

    Creating appdirs requires:
     - passing environment variables, only on unix and osx systems.
     - a name of the app you want to get directories for
     - optionally: a name of the app author (be it a company or a person)
     - optionally: a version of your app, if you want to separate directories also by version
    """
    _env_vars = EnvVars(env_vars)
    _app_name = app_name
    _app_author = app_author
    _app_version = app_version
    _roaming = roaming
    _osx_as_unix = osx_as_unix

    _home = ifdef windows then
      try KnownFolders(KnownFolderIds.profile())? end
    else
      try _env_vars("HOME")? end
    end

  fun _expand_user(path: String): String ? =>
    (_home as String).join(path.split_by("~").values())

  fun user_home_dir(): String ? =>
    _home as String

  fun user_data_dir(): String ? =>
    """
    Returns the full path to the user-specific data dir for this application.
    """
    let os_specific_dir =
      ifdef osx then
        if _osx_as_unix then
          _unix_user_data_dir()?
        else
          Paths.join([_home as String; "Library"; "Application Support"; _app_name])
        end
      elseif windows then
        let folder_id =
          if _roaming then
            KnownFolderIds.app_data_roaming()
          else
            KnownFolderIds.app_data_local()
          end
        Paths.join([
          KnownFolders(folder_id)?
          _Opt.get[String](_app_author, "")
          _app_name
        ])
      else
        // *nix
        _unix_user_data_dir()?
      end
    match _app_version
    | None => os_specific_dir
    | let v: String => Path.join(os_specific_dir, v)
    end

  fun _unix_user_data_dir(): String ? =>
    let base_path =
      _env_vars.get_or_else(
        "XDG_DATA_HOME",
        Paths.join([_home as String; ".local"; "share"]))
    Path.join(
      _expand_user(base_path)?, // make sure any '~' get replaced by the users home directory
      _app_name)

  fun site_data_dirs(): Array[String] val ? =>
    """
    Returns an array of full paths to the user-shared data dirs for this application.
    """
    let os_specific_dirs: Array[String] iso =
      ifdef osx then
        if _osx_as_unix then
          _unix_site_data_dirs()?
        else
          recover [Path.join("/Library/Application Support", _app_name)] end
        end
      elseif windows then
        recover
          [
            Paths.join([
              KnownFolders(KnownFolderIds.program_data())?
              _Opt.get[String](_app_author, "")
              _app_name
            ])
          ] end
      else
        //*nix
        _unix_site_data_dirs()?
      end
    match _app_version
    | let v: String =>
      for i in Range[USize](0, os_specific_dirs.size()) do
        os_specific_dirs(i)? = Path.join(os_specific_dirs(i)?, v)
      end
    end
    os_specific_dirs

  fun _unix_site_data_dirs(): Array[String] iso^ ? =>
    let data_dirs: Array[String] iso =
      try
        Path.split_list(_env_vars("XDG_DATA_DIRS")?)
      else
        // fallback default dirs
        recover iso ["/usr/local/share"; "/usr/share"] end
      end

    for idx in Range[USize](0, data_dirs.size()) do
      data_dirs(idx)? = Path.join(data_dirs(idx)?, _app_name)
    end
    consume data_dirs

  fun user_config_dir(): String ? =>
    """
    Return full path to the user-specific config dir for this application.
    """
    ifdef windows then
      user_data_dir()?
    else
      let os_specific_dir =
        ifdef osx then
          if _osx_as_unix then
            _unix_user_config_dir()?
          else
            Paths.join([_home as String; "Library"; "Preferences"; _app_name])
          end
        else
          // *nix
          _unix_user_config_dir()?
        end

      // apply version
      match _app_version
      | None => os_specific_dir
      | let v: String => Path.join(os_specific_dir, v)
      end
    end

  fun _unix_user_config_dir(): String ? =>
    let base_path =
      _env_vars.get_or_else(
        "XDG_CONFIG_HOME",
        Path.join(_home as String, ".config"))
    Path.join(
      _expand_user(base_path)?,
      _app_name)

  fun site_config_dirs(): Array[String] val ? =>
    """
    Return full path to the user-shared config dirs for this application.
    """
    ifdef windows then
      site_data_dirs()?
    else
      let os_specific_dirs: Array[String] iso =
        ifdef osx then
          if _osx_as_unix then
            _unix_site_config_dirs()?
          else
            recover [Path.join("/Library/Preferences", _app_name)] end
          end
        else
          //*nix
          _unix_site_config_dirs()?
        end

      match _app_version
      | let v: String =>
        for i in Range[USize](0, os_specific_dirs.size()) do
          os_specific_dirs(i)? = Path.join(os_specific_dirs(i)?, v)
        end
      end
      os_specific_dirs
    end

  fun _unix_site_config_dirs(): Array[String] iso^ ? =>
    let config_dirs: Array[String] iso =
      try
        Path.split_list(_env_vars("XDG_CONFIG_DIRS")?)
      else
        // fallback default dirs
        recover iso ["/etc/xdg"] end
      end

    for idx in Range[USize](0, config_dirs.size()) do
      config_dirs(idx)? = Path.join(config_dirs(idx)?, _app_name)
    end
    consume config_dirs

  fun user_cache_dir(): String ? =>
    """
    Return full path to the user-specific cache dir for this application.
    """
    let os_specific_dir =
      ifdef osx then
        if _osx_as_unix then
          _unix_user_cache_dir()?
        else
          Paths.join([_home as String; "Library"; "Caches"; _app_name])
        end
      elseif windows then
        let known_folder: String val =
          KnownFolders(KnownFolderIds.app_data_local())?
        Paths.join([
          known_folder
          _Opt.get[String](_app_author, "")
          _app_name
          "Cache"
        ])
      else
        // *nix
        _unix_user_cache_dir()?
      end
    match _app_version
    | None => os_specific_dir
    | let v: String => Path.join(os_specific_dir, v)
    end

  fun _unix_user_cache_dir(): String ? =>
    Path.join(
      _expand_user(_env_vars.get_or_else("XDG_CACHE_HOME", "~/.cache"))?,
      _app_name)

  fun user_state_dir(): String ? =>
    """
    Return full path to the user-specific state dir for this application.

    See https://wiki.debian.org/XDGBaseDirectorySpecification#state
    """
    ifdef osx then
      if _osx_as_unix then
        _unix_user_state_dir()?
      else
        user_data_dir()?
      end
    elseif windows then
      user_data_dir()?
    else
      // *nix
      _unix_user_state_dir()?
    end

  fun _unix_user_state_dir(): String ? =>
    Paths.join([
      _expand_user(
        _env_vars.get_or_else(
          "XDG_STATE_HOME",
          "~/.local/state"))?
      _app_name
      _Opt.get[String](_app_version, "")
    ])

  fun user_log_dir(): String ? =>
    """
    Return full path to the user-specific log dir for this application.
    """
    ifdef osx then
      if _osx_as_unix then
        _unix_user_log_dir()?
      else
        Paths.join([
          _home as String
          "Library"
          "Logs"
          _app_name
          _Opt.get[String](_app_version, "")
        ])
      end
    elseif windows then
      user_data_dir()?
    else
      // *nix
      _unix_user_log_dir()?
    end

  fun _unix_user_log_dir(): String ? =>
    Path.join(
      user_cache_dir()?,
      "log")


