{ lib

, stdenv
, fetchFromGitHub
, glibc
, llvmPackages
, rustPlatform

, bch_bindgen

, ...
}: rustPlatform.buildRustPackage ( let
  info = lib.importJSON ./version.json;
  tools_src = fetchFromGitHub {inherit (info) owner repo rev sha256;};
  cargo = lib.trivial.importTOML "${tools_src}/rust-src/mount/Cargo.toml";
in {
  pname = "mount.bcachefs";
  version = cargo.package.version;

  # inherit src;
  src = builtins.path { path = "${tools_src}/rust-src"; name = "rust-src"; };
  sourceRoot = "rust-src/mount";

  cargoLock = { lockFile = "${tools_src}/rust-src/mount/Cargo.lock"; };

  nativeBuildInputs = bch_bindgen.nativeBuildInputs;
  buildInputs = bch_bindgen.buildInputs;
  inherit (bch_bindgen)
    LIBBCACHEFS_INCLUDE
    LIBBCACHEFS_LIB
    LIBCLANG_PATH
    BINDGEN_EXTRA_CLANG_ARGS;

  postInstall = ''
    ln $out/bin/${cargo.package.name} $out/bin/mount.bcachefs
    ln -s $out/bin $out/sbin
  '';
  # -isystem ${llvmPackages.libclang.lib}/lib/clang/${lib.getVersion llvmPackages.libclang}/include";
  # CFLAGS = "-I${llvmPackages.libclang.lib}/include";
  # LDFLAGS = "-L${libcdev}";

  doCheck = false;

  # NIX_DEBUG = 4;
})
