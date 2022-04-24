{
  inputs.hakyll = {
    url = "github:jaspervdj/hakyll/master";
    flake = false;
  };
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";

  #inputs.justinrestivo_resume = {
  #url = "git+ssh://git@github.com/DieracDelta/resume";
  #flake = true;
  #};

  outputs = { self, nixpkgs, hakyll, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (builtins) filterSource;
        inherit (nixpkgs.lib) flip;
        inherit (pkgs.nix-gitignore) gitignoreSourcePure;

        envVars = 
            (pkgs.lib.optionals pkgs.stdenv.isLinux ''export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive";'') +
            ''export LANG=en_US.UTF-8;'';

        src = gitignoreSourcePure [ ./.gitignore ] ./.;
        overlay = final: prev: {
          haskell = prev.haskell // {
            packageOverrides = prev.lib.composeExtensions
              (prev.haskell.packageOverrides or (_: _: { }))
              (hself: hsuper: {
                hakyll =
                prev.haskell.lib.dontCheck 
                  (hself.callCabal2nix "hakyll" hakyll { });
                builder = prev.haskell.lib.justStaticExecutables
                  (hself.callCabal2nix "builder" src { });
              });
          };

          justinrestivo-me-builder = final.haskellPackages.builder;
          justinrestivo-me = final.stdenv.mkDerivation {
            name = "justinrestivo-me";
            src = src;
            phases = "unpackPhase buildPhase";
            buildInputs = [ final.justinrestivo-me-builder ];
            buildPhase = 
            envVars +
            ''
              site build
              mkdir -p $out
              echo "justin.restivo.me" >> $out/CNAME
              cp -r _site/* $out
              cp sitemap.xml $out
            '';
          };
        };
        pkgs = import nixpkgs {
          system = system;
          overlays = [ overlay ];
        };
      in
      {
        defaultPackage = pkgs.justinrestivo-me;
        defaultApp = flake-utils.lib.mkApp {
          drv = pkgs.justinrestivo-me;
          exePath = "/bin/hakyll-site";
        };
        packages = {
          inherit (pkgs) justinrestivo-me-builder justinrestivo-me;
        };
        devShell =
          #   pkgs.haskellPackages.shellFor {
          #   packages = p: [ p.justinrestivo-me-builder ];
          # };
          pkgs.mkShell {
            nativeBuildInputs = with pkgs; [ pkgs.haskellPackages.hakyll pandoc ];
          };
      }

    );
}
