{
  description = "Cpp Playground";

  inputs = {
    # Nixpkgs (take the systems nixpkgs version)
    nixpkgs.url = "nixpkgs";

    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgsStable.url = "github:nixos/nixpkgs/nixos-23.11";
    # Also see the 'stable-packages' overlay at 'overlays/default.nix'.
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgsStable,
    ...
  } @ inputs: let
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "x86_64-linux"
      "aarch64-darwin"
    ];

    # This is a function that generates an attribute by calling a function you
    # pass to it, with the correct `system` and `pkgs` as arguments.
    forAllSystems = func: nixpkgs.lib.genAttrs systems (system: func system nixpkgs.legacyPackages.${system});
  in {
    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: pkgs: pkgs.alejandra);

    devShells =
      forAllSystems
      (
        system: pkgs: let
          # Some Node packages for development.
          nodePackages = pkgs.callPackage ./tools/nix/node-packages/default.nix {};

          # Toolchain.
          gccVersion = "13";
          gccPkg = pkgs."gcc${gccVersion}";

          llvmVersion = "17";
          llvmPkgs = pkgs."llvmPackages_${llvmVersion}";
          # clangStdEnv = pkgs.clang17Stdenv;

          clangStdEnv = pkgs.stdenvAdapters.overrideCC llvmPkgs.stdenv (llvmPkgs.clang.override {
            gccForLibs = gccPkg.cc;
            # bintools = llvmPkgs.bintools;
          });

          # What goes here:
          # Dependencies which will end up copied or linked into the final
          # output or otherwise used at runtime.
          # https://nixos.org/manual/nixpkgs/stable/#ssec-stdenv-dependencies-overview
          buildInputs = with pkgs; [
            # Dependencies
            fmt
          ];

          # What goes here:
          # Stuff that is run at build time.
          # https://nixos.org/manual/nixpkgs/stable/#ssec-stdenv-dependencies-overview
          nativeBuildInputs = with pkgs; [
            # Other tools
            ninja
            cmake
          ];
        in {
          # default = pkgs.mkShell.override {stdenv = clangStdEnv;} rec {
          default = pkgs.mkShell.override {stdenv = clangStdEnv;} {
            inherit nativeBuildInputs;
            inherit buildInputs;

            LD_LIBRARY_PATH = nixpkgs.lib.makeLibraryPath [gccPkg.cc.lib pkgs.fmt];
          };
        }
      );
  };
}
