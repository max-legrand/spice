{
  inputs = {
    opam-nix.url = "github:tweag/opam-nix";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "opam-nix/nixpkgs";
  };
  outputs = { self, flake-utils, opam-nix, nixpkgs }@inputs:
    let package = "spice";
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        on = opam-nix.lib.${system};
        scope = on.buildOpamProject { } package ./. { 
          ocaml-base-compiler = "5.2.0";
          # Add other version constraints here if needed
        };
        overlay = final: prev: {
          # Add system dependencies for ocurl
          ocurl = prev.ocurl.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [ 
              pkgs.curl
              pkgs.curl.dev
            ];
          });
        } // (pkgs.lib.optionalAttrs (pkgs.stdenv.isDarwin) {
          # Disable codesign requirement for caqti only on macOS
          caqti = prev.caqti.overrideAttrs (old: {
            preBuild = ''
              # Create a dummy codesign script
              mkdir -p $TMP/bin
              echo '#!/bin/sh' > $TMP/bin/codesign
              chmod +x $TMP/bin/codesign
              export PATH="$TMP/bin:$PATH"
            '';
          });
        });
        scope' = scope.overrideScope overlay;

        # Create a package with proper installation
        finalPackage = scope'.${package}.overrideAttrs (old: {
          buildPhase = ''
            dune build --release @install
          '';
          installPhase = ''
            mkdir -p $out/lib/ocaml/5.2.0/site-lib
            dune install --prefix $out --libdir $out/lib/ocaml/5.2.0/site-lib --release
          '';
        });

      in {
        legacyPackages = scope';

        packages = {
          default = finalPackage;
          ${package} = finalPackage;
        };
        apps.default = {
          type = "app";
          program = "${finalPackage}/bin/${package}";
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.default ];
          buildInputs = with pkgs; [
            # Development tools
            ocamlPackages.ocaml-lsp
            ocamlPackages.ocamlformat
            # Add curl to devShell as well
            curl
            curl.dev
          ];
        };
      });
}
