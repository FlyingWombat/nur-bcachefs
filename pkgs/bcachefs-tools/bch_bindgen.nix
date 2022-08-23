{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, llvmPackages
, bcachefs-tools
, pkg-config

, udev
, liburcu
, zstd
, keyutils
, libaio

, lz4 # liblz4
, libsodium
, libuuid
, zlib # zlib1g
, libscrypt
, util-linux

, rustfmt

, glibc
, ...
}: let
  include = let
    convertToIncludes = map (inc: "-I"+inc);
    catStrings = lib.concatStringsSep " ";
    makeIncludes = i: catStrings (convertToIncludes (builtins.attrValues i));
    in makeIncludes {
      glibc = "${glibc.dev}/include";
      clang = let libc = llvmPackages.libclang; in
        "${libc.lib}/lib/clang/${libc.version}/include";
      urcu = "${liburcu}/include";
      zstd = "${zstd.dev}/include";
      blkid = "${util-linux.dev}/include/blkid";
      util-linux = "${util-linux.dev}/include";
      bcachefs = "${bcachefs-tools.src}";
      bcachefs-include = "${bcachefs-tools.src}/include";

    };

  info = lib.importJSON ./version.json;
  tools_src = fetchFromGitHub {inherit (info) owner repo rev sha256;};
  cargo = lib.trivial.importTOML "${tools_src}/rust-src/bch_bindgen/Cargo.toml";
in rustPlatform.buildRustPackage {
  pname = cargo.package.name;
  version = cargo.package.version;

  src = builtins.path { path = "${tools_src}/rust-src"; name = "rust-src"; };
  sourceRoot = "rust-src/bch_bindgen";

  cargoLock = { lockFile = "${tools_src}/rust-src/bch_bindgen/Cargo.lock"; };

  nativeBuildInputs = [ rustfmt pkg-config ];
  buildInputs = [

    # libaio
    keyutils # libkeyutils
    lz4 # liblz4
    libsodium
    liburcu
    libuuid
    zstd # libzstd
    zlib # zlib1g
    udev
    libscrypt
    libaio
    util-linux.dev
  ];

  LIBBCACHEFS_LIB = "${bcachefs-tools}/lib";
  LIBBCACHEFS_INCLUDE = "${bcachefs-tools.src}";
  LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
  BINDGEN_EXTRA_CLANG_ARGS = lib.replaceStrings ["\n" "\t"] [" " ""] ''
    -std=gnu99
  '' + include;
    # -llibblkid


  doCheck = true;

  # NIX_DEBUG = 4;
}
