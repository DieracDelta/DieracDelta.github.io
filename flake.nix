{
  inputs.hakyll = {
    url = "github:jaspervdj/hakyll/master";
    flake = false;
  };

  #inputs.justinrestivo_resume = {
    #url = "git+ssh://git@github.com/DieracDelta/resume";
    #flake = true;
  #};

  outputs = { self, nixpkgs, hakyll}:
    let
      inherit (builtins) filterSource;
      inherit (nixpkgs.lib) flip;
      inherit (pkgs.nix-gitignore) gitignoreSourcePure;

      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ self.overlay ];
      };
      src = gitignoreSourcePure [ ./.gitignore ] ./.;

    in {
      overlay = final: prev: {
        haskell = prev.haskell // {
          packageOverrides = prev.lib.composeExtensions
            (prev.haskell.packageOverrides or (_: _: { })) (hself: hsuper: {
              hakyll = hself.callCabal2nix "hakyll" hakyll { };
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
          buildPhase = ''
            export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive";
            export LANG=en_US.UTF-8
            site build
            mkdir -p $out
            echo "justin.restivo.me" >> $out/CNAME
            cp -r _site/* $out
            cp sitemap.xml $out
          '';
        };
      };

      defaultPackage.x86_64-linux = self.packages.x86_64-linux.justinrestivo-me;
      packages.x86_64-linux = {
        inherit (pkgs) justinrestivo-me-builder justinrestivo-me;
      };
      devShell.x86_64-linux =
        #   pkgs.haskellPackages.shellFor {
        #   packages = p: [ p.justinrestivo-me-builder ];
        # };
        pkgs.mkShell {
          nativeBuildInputs = [ pkgs.justinrestivo-me-builder pkgs.pandoc ];
        };
    };
}
