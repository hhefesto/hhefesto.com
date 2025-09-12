{
  description = "PureScript landing page (reproducible, network-free)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Tooling & reproducible builder
    purescript-overlay = {
      url = "github:thomashoneyman/purescript-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mkSpagoDerivation.url = "github:jeslie0/mkSpagoDerivation";

    # (optional) secrets
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, flake-parts, purescript-overlay, mkSpagoDerivation, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { system, self', ... }: let
        # Import nixpkgs WITH the overlays applied
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            mkSpagoDerivation.overlays.default
            purescript-overlay.overlays.default
          ];
        };
      in {
        # Make this pkgs (with overlays) the one flake-parts uses everywhere in this system
        _module.args.pkgs = pkgs;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # Modern (YAML) Spago & compiler from the overlay
            spago-unstable
            purs-unstable
            esbuild
            watchexec
            jq
            inputs.agenix.packages.${system}.default
            busybox
          ];
          shellHook = ''
            echo "PureScript Landing Page (reproducible)"
            echo "• spago build        - typecheck/compile (creates spago.lock)"
            echo "• spago bundle       - bundle to index.js"
            echo 'to preview: nix build .#github-pages && busybox httpd -f -p 8000 -h ./result;'
          '';
        };

        packages = {
          # Fully reproducible PureScript build using your spago.lock (no network)
          website = pkgs.mkSpagoDerivation {
            src = ./.;
            spagoYaml = ./spago.yaml;
            spagoLock = ./spago.lock;

            version = "0.1.0";
            nativeBuildInputs = with pkgs; [ spago-unstable purs-unstable esbuild ];

            # If you also need reproducible npm deps later, uncomment:
            # buildNodeModulesArgs = {
            #   npmRoot = ./.;
            #   nodejs = pkgs.nodejs;
            # };

            # Bundle PureScript app to ./index.js
            buildPhase = ''
              set -euo pipefail
              export HOME="$PWD/.nix-build-home"
              spago bundle
            '';

            # Stage a static site
            installPhase = ''
              set -euo pipefail
              mkdir -p "$out"
              if [ -d public ]; then
                cp -r public/* "$out"/
              else
                cat > "$out/index.html" <<'HTML'
              <!doctype html>
              <meta charset="utf-8"/>
              <meta name="viewport" content="width=device-width, initial-scale=1"/>
              <title>My Landing</title>
              <button id="cta">Click me</button>
              <p id="app"></p>
              <script type="module" src="./index.js"></script>
              HTML
              fi
              cp index.js "$out"/
              [ -d assets ] && cp -r assets "$out"/
            '';
          };

          # Publishable artifact for GitHub Pages
          github-pages = pkgs.runCommand "hhefesto-landing-gh-pages" { } ''
            set -euo pipefail
            mkdir -p "$out"
            cp -r ${self'.packages.website}/* "$out"/
            touch "$out/.nojekyll"
            # write your custom domain here
            echo "hhefesto.com" > "$out/CNAME"
          '';

          default = self'.packages.github-pages;
        };

        checks = {
          typecheck = pkgs.runCommand "purescript-typecheck" {
            nativeBuildInputs = with pkgs; [ spago-unstable purs-unstable ];
          } ''
            set -euo pipefail
            cp -r ${./.} ./
            chmod -R +w .
            export HOME="$PWD/.nix-build-home"
            spago build
            touch "$out"
          '';
          bundle = self'.packages.website;
        };
      };
    };
}
