{
  description = "A simple set of scripts and systemd units for taking and managing BTRFS snapshots";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { flake-parts, ... }: flake-parts.lib.mkFlake { inherit inputs; } (
    { moduleWithSystem, ... }:
    {
      systems = [
        "i686-linux"
        "x86_64-linux"
        "aarch64-linux"
        "armv7l-linux"
      ];
      imports = [ flake-parts.flakeModules.easyOverlay ];
      perSystem = { config, system, lib, pkgs, ...}:
        let
          btrfs-snapshot = pkgs.stdenv.mkDerivation {
            pname = "btrfs-snapshot";
            version = "1.0.0";
            src = ./.;
            strictDeps = true;
            runtimeInputs = with pkgs; [ util-linux btrfs-progs coreutils ];
            nativeBuildInputs = with pkgs; [ gnumake m4 makeWrapper ];
            makeFlags = [
              "PREFIX=$(out)"
              "SYSTEMD_UNIT_DIR=$(out)/share/systemd"
            ];
            postInstall = ''
              for i in $out/bin/*; do
                wrapProgram $i --prefix PATH : "${lib.makeBinPath (with pkgs; [ util-linux btrfs-progs])}"
              done
            '';
          };
        in rec {
          packages = {
            inherit btrfs-snapshot;
            default = packages.btrfs-snapshot;
          };
          overlayAttrs = {
            inherit (config.packages) btrfs-snapshot;
          };
        };
      flake.nixosModules.default = moduleWithSystem (
        perSystem@{pkgs, self', ... }:
        nixos@{lib, config, ... }:
        let
          cfg = config.services.btrfs-snapshot;
        in
        {
          options.services.btrfs-snapshot = {
            install = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Whether to install the systemd units for btrfs-snapshot.

                The units must be manually enabled for each subvolume.
              '';
            };
            package = lib.mkPackageOption self'.packages "btrfs-snapshot" { };
          };
          config = lib.mkIf cfg.install {
            systemd = {
              packages = [ cfg.package ];
            };
            environment.systemPackages = [ cfg.package ];
          };
        });
    });
  }
