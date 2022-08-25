# fetch bcachefs-kernel from git source
# intended for use with a local clone, since this doesn't merge in minor kernel
# revisions.
{ lib
, fetchpatch
, fetchgit
, buildLinux
, kernelPatches ? []
, modDirVersionArg ? null
, structuredExtraConfig ? {}
, argsOverride ? {}
, debug_fs ? false
, ...
} @ args:

let info = lib.importJSON ./version.json;
    versionString = builtins.substring 0 8 info.rev;
in
buildLinux (args // {
    # pname = "linux";
    version = "${info.kernelVersion}-bcachefs-${versionString}";

    # modDirVersion needs to be x.y.z
    modDirVersion = info.kernelVersion;

    src = fetchgit { inherit (info) rev sha256 url; };

    structuredExtraConfig = with lib.kernel; {
      BCACHEFS_FS = yes;
      BCACHEFS_QUOTA = yes;
      BCACHEFS_POSIX_ACL = yes;
    } // ( if debug_fs then {
      BCACHEFS_LOCK_TIME_STATS = yes;
      BCACHEFS_DEBUG = yes;
      PREEMPT = lib.mkForce yes;  # mkForce to override default setting
      PREEMPT_VOLUNTARY = lib.mkForce no;
      KALLSYMS = yes;
      KALLSYMS_ALL = yes;
      DEBUG_FS = yes;
      DYNAMIC_FTRACE = yes;
      FTRACE = yes;
    } else {} ) // structuredExtraConfig;


    # NIX_DEBUG=5;
} // (args.argsOverride or {}))
