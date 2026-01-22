{
  description = "A simple set of scripts and systemd units for taking and managing BTRFS snapshots";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      eachSystem = nixpkgs.lib.genAttrs [
        "i686-linux"
        "x86_64-linux"
        "aarch64-linux"
        "armv7l-linux"
      ];
      mkPackages = pkgs: rec {
        btrfs-snapshot =
          (pkgs.resholve.mkDerivation {
            pname = "btrfs-snapshot";
            version = "1.0.0";
            src = ./.;
            strictDeps = true;
            nativeBuildInputs = with pkgs; [
              gnumake
              m4
            ];
            makeFlags = [
              "DESTDIR=$(out)"
              "PREFIX="
              "SYSTEMD_UNIT_DIR=share/systemd"
            ];
            solutions = {
              btrfs-snapshot = {
                interpreter = "${pkgs.bash}/bin/bash";
                scripts = [
                  "lib/btrfs-snapshot-common.sh"
                  "bin/btrfs-snapshot"
                  "bin/btrfs-snapshot-cleanup"
                ];
                inputs = with pkgs; [
                  util-linux
                  btrfs-progs
                  coreutils
                  findutils
                  git
                ];
                execer = [
                  "cannot:${pkgs.util-linux}/bin/flock"
                  "cannot:${pkgs.git}/bin/git"
                ];
              };
            };
          }).overrideAttrs
            (old: {
              preFixup = ''
                substituteInPlace $out/share/systemd/*/*.service \
                  --replace-quiet "/bin/" "$out/bin/"
              ''
              + old.preFixup;
            });
        default = btrfs-snapshot;
      };
    in
    {
      packages = eachSystem (system: mkPackages nixpkgs.legacyPackages.${system});

      formatter = eachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      overlays.default = final: prev: {
        inherit (mkPackages final) btrfs-snapshot;
      };

      nixosModules.default =
        {
          lib,
          config,
          pkgs,
          ...
        }:
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
            package = lib.mkPackageOption (mkPackages pkgs) "btrfs-snapshot" { };
          };
          config = lib.mkIf cfg.install {
            systemd.packages = [ cfg.package ];
          };
        };
    };
}
