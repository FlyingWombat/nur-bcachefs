{
  system ? builtins.currentSystem,
  nixpkgs ? <nixpkgs>,
  pkgs ? import nixpkgs {}
  }:
let
  kernelPatches = [
    pkgs.kernelPatches.bridge_stp_helper
    pkgs.kernelPatches.request_key_helper
  ];
  lib = import ./lib { inherit pkgs; }; # functions

  bcachefs-tools = pkgs.callPackage ./pkgs/bcachefs-tools { };
  bcachefs-bch-bindgen = pkgs.callPackage ./pkgs/bcachefs-tools/bch_bindgen.nix { inherit bcachefs-tools; };
  bcachefs-mount = pkgs.callPackage ./pkgs/bcachefs-tools/mount.nix { bch_bindgen = bcachefs-bch-bindgen; };
  bcachefs-kernel-git = pkgs.callPackage ./pkgs/bcachefs-kernel-git {
    debug_fs = true;
    inherit kernelPatches;
  };
  bcachefs-kernel = pkgs.callPackage ./pkgs/bcachefs-kernel {
    kernel = pkgs.linuxKernel.kernels.linux_5_19;
    inherit kernelPatches;
  };
in
{
  inherit
    bcachefs-bch-bindgen
    bcachefs-mount
    bcachefs-tools
    bcachefs-kernel
    bcachefs-kernel-git
    lib;
  # The `lib`, `modules`, and `overlay` names are special
  modules = import ./modules; # NixOS modules
  overlays = import ./overlays; # nixpkgs overlays
  bcachefs-iso = (import "${toString nixpkgs}/nixos/lib/eval-config.nix" {
      inherit system;
      modules = [
        ({...}: {
          nixpkgs.overlays = [(super: final: { inherit bcachefs-tools bcachefs-kernel;})];
        })
        (
          ./iso.nix
        )
      ];
  }).config.system.build.isoImage;
}
