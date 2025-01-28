{
  description = "The flake that is used compile latex documents.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-github-actions = {
      url = "github:nix-community/nix-github-actions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { 
    self, 
    nixpkgs, 
    flake-utils, 
    nix-github-actions, 
    ... 
  } @ inputs: flake-utils.lib.eachDefaultSystem ( system:
    let

      pkgs = import nixpkgs { inherit system; };
      
    in rec {

      checks.default = self.packages.${system}.default;

      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [ 
          texliveFull  # Compile the latex manually.
          act          # Run GitHub Actions locally.
        ];
      };

      packages.default = pkgs.stdenv.mkDerivation rec {
        name = "automata-report";
        src = ./.;
        buildInputs = with pkgs; [ texliveFull ];

        buildPhase = ''
          runHook preBuild 

          pdflatex --halt-on-error --file-line-error --interaction=nonstopmode \
            --output-directory=. ./main.tex
          
          runHook postBuild
        '';

        installPhase = ''
          mkdir --parents $out/doc
          mv ./main.pdf $out/doc/assignments.pdf
        '';
      };
    }
  ) // {
    githubActions = nix-github-actions.lib.mkGithubMatrix {
      checks = nixpkgs.lib.getAttrs [ "x86_64-linux" ] self.checks;
    };
  };
}
