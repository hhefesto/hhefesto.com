{
  # hhefesto.dev: the landing page, a bend-frp app written in Bend
  # (src/Main.bend), the booking logic it offers the free call with
  # (src/Book.bend), that logic's laws (LAWS.bend, proven in PROOF.bend) and
  # its tests (tests/book.bend). public/ holds the files served as they are:
  # og.png, CNAME, CV-Daniel-Herrera.pdf (the CV: `nix build` of
  # github.com/hhefesto/cv), and slots.json, which `horas publish` writes.
  #
  #   nix build .#site         the site as GitHub Pages serves it (checks the
  #                            Bend and the proofs first)
  #   nix flake check          that, the tests, and the proofs rechecked by
  #                            BendTT's kernel (--verdict)
  description = "hhefesto.dev: a landing page in Bend, on bend-frp";

  inputs = {
    # bend-frp: the FRP library and web runtime the page is built on. Its
    # flake pins Bend (2.0.39, as horas and ana) and builds BendTT, the
    # kernel `bend --verdict` checks with.
    bend-frp.url = "github:hhefesto/bend-frp";
    nixpkgs.follows = "bend-frp/nixpkgs";
  };

  outputs =
    { self, nixpkgs, bend-frp }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      each = f: nixpkgs.lib.genAttrs systems (system: f system nixpkgs.legacyPackages.${system});
      src = nixpkgs.lib.fileset.toSource {
        root = ./.;
        fileset = nixpkgs.lib.fileset.unions [
          ./src
          ./tests
          ./public
          ./LAWS.bend
          ./PROOF.bend
        ];
      };
      # Bend alone: the site builds without Lean.
      bendOf = system: bend-frp.inputs.bend2.packages.${system}.default;
      # Bend with BendTT, for --verdict.
      bendttOf = system: bend-frp.packages.${system}.bend;
      # `script` in a writable copy of the site, with bend-frp beside it, as
      # src/Main.bend imports it (../../bend-frp, as in ~/src).
      inSource =
        pkgs: bend: name: script:
        pkgs.runCommand "hhefesto-dev-${name}" { nativeBuildInputs = [ bend ]; } ''
          export HOME=$TMPDIR BEND_NO_TELEMETRY=1
          mkdir w
          cp -r ${src} w/hhefesto.com
          cp -r ${bend-frp} w/bend-frp
          chmod -R u+w w
          cd w/hhefesto.com
          ${script}
        '';
      gate = file: ''
        bend --check-only ${file} 2>&1 | tee check.log
        grep -q 'ALL PROOFS CHECK' check.log
      '';
    in
    {
      packages = each (
        system: pkgs: rec {
          # The page and its JavaScript (bend bundles src/index.html), then
          # public/ as it is.
          site = inSource pkgs (bendOf system) "site" ''
            ${gate "src/Main.bend"}
            ${gate "PROOF.bend"}
            bend src/index.html -o $out
            cp -r public/. $out/
          '';
          github-pages = site;
          default = site;
        }
      );

      checks = each (
        system: pkgs: {
          inherit (self.packages.${system}) site;
          # the laws hold: Bend's checker, then BendTT's kernel
          verdict = inSource pkgs (bendttOf system) "verdict" ''
            bend PROOF.bend --verdict 2>&1 | tee $out
            grep -q 'ALL PROOFS CHECK' $out
          '';
          # what the proofs cannot say: the dates, times and email text
          tests = inSource pkgs (bendOf system) "tests" ''
            bend tests/book.bend -o book-test
            ./book-test | tee $out
          '';
        }
      );

      devShells = each (
        system: pkgs: {
          default = pkgs.mkShell {
            packages = [
              (bendttOf system)
              pkgs.darkhttpd
            ];
            shellHook = ''
              echo "hhefesto.dev, in Bend"
              echo "  nix build .#site && darkhttpd result --port 8000   preview"
              echo "  bend PROOF.bend --verdict                          the laws"
              echo "  bend tests/book.bend                               the tests"
            '';
          };
        }
      );
    };
}
