{
  description = "Developer documentation for the Rivaas Go framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        # Development shell with Go and Hugo
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            git
            hugo
            gum
            nodejs_24
          ];

          shellHook = ''
            export NODE_PATH=$PWD/node_modules
            gum style --foreground 158 "$(cat logo.txt)"

            npm install
          '';
        };
      }
    );
}

