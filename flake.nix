{
  description = "Egypt Transporation Agent-based Model";

  # https://github.com/cachix/pre-commit-hooks.nix
  inputs.pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";

  inputs.nixpkgs-unstable-25.url = "github:NixOS/nixpkgs/aefcb0d50d1124314429a11ed6b7aaaedf2861c5";
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/bd9b686c0168041aea600222be0805a0de6e6ab8";
  inputs.nixpkgs.url =
    "github:NixOS/nixpkgs/da5adce0ffaff10f6d0fee72a02a5ed9d01b52fc";
  inputs.nixpkgsMaven.url =
    "github:NixOS/nixpkgs/4d887ae7666a6ffb79e1767d8fd417daf9e4220f";

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-unstable-25, nixpkgsMaven, ... }@inputs:
    let
      supportedSystems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f:
        nixpkgs.lib.genAttrs supportedSystems (system:
          f {
            pre-commit-hooks-run = inputs.pre-commit-hooks.lib.${system}.run;
            pkgs = import nixpkgs-unstable {
              inherit system;
              overlays = [
                (final: prev: rec {
                  jdk = prev.jdk11;
                  # python310 = prev.python310.override {
                  #   self = prev.python310;
                  #   packageOverrides = python_final: python_prev: {
                  #     polars = python_prev.polars.overridePythonAttrs (old: rec {
                  #       version = "0.19.1";
                  #       src = prev.fetchFromGitHub {
                  #         owner = "pola-rs";
                  #         repo = "polars";
                  #         rev = "refs/tags/py-${version}";
                  #         hash = "sha256-kV30r2wmswpCUmMRaFsCOeRrlTN5/PU0ogaU2JIHq0E=";
                  #       };
                  #       cargoDeps = prev.rustPlatform.importCargoLock {
                  #         lockFile = ./Cargo.lock;
                  #         outputHashes = {
                  #           "arrow2-0.17.4" = "sha256-pM6lNjMCpUzC98IABY+M23lbLj0KMXDefgBMjUPjDlg=";
                  #           "jsonpath_lib-0.3.0" = "sha256-NKszYpDGG8VxfZSMbsTlzcMGFHBOUeFojNw4P2wM3qk=";
                  #           # "simd-json-0.10.0" = "sha256-0q/GhL7PG5SLgL0EETPqe8kn6dcaqtyL+kLU9LL+iQs=";
                  #         };
                  #       };
                  #     });
                  #   };
                  # };
                })
              ];
            };
            pkgs-25 = import nixpkgs-unstable-25 {
              inherit system;
              config.allowUnfree = true;
            };
            
            pkgs-23-05 = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            nixpkgsMaven = import nixpkgsMaven { inherit system; };
            inherit system;

          });
    in {
      checks = forEachSupportedSystem ({ pre-commit-hooks-run, ... }: {
        pre-commit-check = pre-commit-hooks-run {
          src = ./.;
          hooks = {
            black = {
              enable = true;
              files = "\\.py$";
            };

            yamllint = {
              enable = false;
              # relaxed = true;
            };
            nixfmt.enable = true;
          };
        };
      });
      devShells = forEachSupportedSystem
        ({ pkgs, pkgs-23-05, pkgs-25, nixpkgsMaven, system, ... }:
          {
            default = pkgs.mkShell {
              shellHook = ''
                # environment variable declaration
                export JAVA_HOME=${pkgs-25.jdk23}
              '';
              # inherit (self.checks.${system}.pre-commit-check) shellHook;
              packages = with pkgs;
                (with pkgs-25; [
                  jdk23
                  maven
                ]);
            };
          });
    };
}
