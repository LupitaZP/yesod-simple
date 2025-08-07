{
  description = "My first flake";

  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self
                   , nixpkgs
                   , flake-utils
                   , haskellNix
                   , flake-compat
                   }:

    let
      overlays =
        [ haskellNix.overlay
          (final: prev: {
            yesod-simple = final.haskell-nix.stackProject {

              src = final.haskell-nix.cleanSourceHaskell {
                src = ./.;
                name = "yesod-simple";
              };

              shell.buildInputs = with pkgs; [
                stack
                stylish-haskell
                haskell-language-server
                haskellPackages.yesod-bin
                hlint
                ghcid
              ];
              shell.additional = hsPkgs: with hsPkgs; [ Cabal ];
            };
            yesod-simple-wrapper = pkgs.writeShellApplication {
              name = "yesod-simple-wrapped";
              runtimeInputs = [ self.packages.x86_64-linux.default ];
              text = ''
               cd D:/yesod-simple
               ${self.packages.x86_64-linux.default}/bin/yesod-simple
              '';
            };
          })
        ];
      pkgs = import nixpkgs { system = "x86_64-linux";
                              inherit overlays;
                              inherit (haskellNix) config;
                            };
      flake = pkgs.yesod-simple.flake {};

    in flake-utils.lib.eachSystem [ "x86_64-linux" ] (system: flake // {
        packages = flake.packages // {
          default = flake.packages."yesod-simple:exe:yesod-simple";
          yesod-simple-wrapper = pkgs.yesod-simple-wrapper;
        };
        apps = flake.apps // { default = flake.apps."yesod-simple:exe:yesod-simple"; };

        legacyPackages = pkgs;
      });

  # --- Flake Local Nix Configuration ----------------------------
  nixConfig = {
    extra-substituters = ["https://cache.iog.io"];
    extra-trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
    allow-import-from-derivation = "true";
  };
}
