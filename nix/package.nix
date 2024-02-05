{
  lib,
  pkgs,
  gccVersion ? "13",
  llvmVersion ? "17",
  build_type ? "release",
  ...
}: let
  # Define settings
  # Toolchain.
  gccVersion = "13";
  gccPkg = pkgs."gcc${gccVersion}";

  llvmVersion = "17";
  llvmPkgs = pkgs."llvmPackages_${llvmVersion}";

  clangStdEnv = pkgs.stdenvAdapters.overrideCC llvmPkgs.stdenv (
    llvmPkgs.clang.override {
      bintools = llvmPkgs.bintools;
      gccForLibs = gccPkg.cc; # This is the unwrapped gcc.
    }
  );

  stdenv = clangStdEnv;
  libstdcxx = gccPkg.cc.lib;

  settings = {
    # What goes here:
    # Dependencies which will end up copied or linked into the final
    # output or otherwise used at runtime.
    # https://nixos.org/manual/nixpkgs/stable/#ssec-stdenv-dependencies-overview
    buildInputs = [
      # Dependencies
      pkgs.fmt
      pkgs.grpc
      pkgs.protobuf
      pkgs.gtest
      pkgs.catch2_3

      # Not necessary
      libstdcxx
    ];

    # What goes here:
    # Stuff that is run at build time.
    # https://nixos.org/manual/nixpkgs/stable/#ssec-stdenv-dependencies-overview
    nativeBuildInputs = [
      # Other tools
      pkgs.just
      pkgs.parallel

      pkgs.ninja
      pkgs.cmake
      pkgs.ccache

      pkgs.python3

      # Override clangd/clang-tidy because of trouble findign stdlib etc.
      # Do not use the clangd from this package as
      # it does not work correctly with
      # Clangd/clang-tidy from clang-tools must come first.
      (pkgs.hiPrio pkgs.clang-tools.override {
        llvmPackages = llvmPkgs;
        enableLibcxx = false;
      })
    ];

    build_dir = "build/no-toolchain-${build_type}";
  };
in
  stdenv.mkDerivation rec {
    pname = "cpp-playground";

    meta = {
      mainProgram = "test";
    };

    version = "0.0.2";

    src = ./..;

    nativeBuildInputs = settings.nativeBuildInputs;
    buildInputs = settings.buildInputs;

    configurePhase = ''
      echo "Out: $out"
      cmake --preset "no-toolchain-${build_type}" \
        "-DCMAKE_INSTALL_PREFIX=$out"

    '';

    buildPhase = ''
      ccache_dir=$(mktemp -d)
      export CCACHE_DIR="$ccache_dir"

      cd "${settings.build_dir}" &&
        NIX_DEBUG=1 cmake --build . -- --verbose
        readelf -d test
        ldd test

      echo "Build Out: $out"
    '';

    installPhase = ''
      cmake --install .
      echo AFTER INSTALL
      readelf -d $out/bin/test
      ldd $out/bin/test

      echo "Out: $out"
    '';
  }
