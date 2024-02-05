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
      gccForLibs = gccPkg.cc; # This is the unwrapped gcc.
    }
  );

  stdenv = clangStdEnv;
  libstdcxx = gccPkg.cc.lib;

  compilerLinks = pkgs.runCommand "clang-links" {} ''
    mkdir -p $out/bin
    ln -s ${llvmPkgs.clang}/bin/clang $out/bin/clang-${llvmVersion}
    ln -s ${llvmPkgs.clang}/bin/clang++ $out/bin/clang++-${llvmVersion}
    ln -s ${llvmPkgs.llvm}/bin/llvm-as $out/bin/llvm-as-${llvmVersion}
  '';

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

      llvmPkgs.lld

      # Override clangd/clang-tidy because of trouble findign stdlib etc.
      # Do not use the clangd from this package as
      # it does not work correctly with
      # Clangd/clang-tidy from clang-tools must come first.
      (pkgs.hiPrio pkgs.clang-tools.override {
        llvmPackages = llvmPkgs;
        enableLibcxx = false;
      })

      # Compiler Links
      compilerLinks
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
        cmake --build . -- --verbose
        ldd test

      echo "Build Out: $out"
    '';

    installPhase = ''
      cmake --install .

      echo "Out: $out"
    '';
  }
