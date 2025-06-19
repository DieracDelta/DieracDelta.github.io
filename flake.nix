{
  description = "Typsite Env";
  inputs = {
    typst.url = "github:typst/typst/";
    typsite.url = "github:Glomzzz/typsite/v0.1.4-24";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      typst,
      typsite,
      flake-utils,
      nixpkgs,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            prettypst
            tinymist
            typst.packages.${system}.default
            typsite.packages.${system}.default
          ];
        };
      }
    );
}
