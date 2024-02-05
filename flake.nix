{
  description = "Cpp Playground";

  nixConfig = {
    substituters = [
      # Add here some other mirror if needed.
      "https://cache.nixos.org/"
    ];
    extra-substituters = [
      # Nix community's cache server
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

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
    formatter = forAllSystems (system: pkgs: pkgs.alejandra);
    packages = forAllSystems (system: pkgs: {
      default = pkgs.callPackage ./nix/package.nix {};
    });
  };
}
