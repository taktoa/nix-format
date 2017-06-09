rec {
  pkgs = import <nixpkgs> {};

  nixMode = pkgs.fetchFromGitHub {
    owner  = "matthewbauer";
    repo   = "nix-mode";
    rev    = "0b19f975cdd24c3a5482053f798e46f7ef2c1ea1";
    sha256 = "1fbq8pxjglh4bhik8g6f2vfmk1s0w2zvbqggm00kyx1kzv60flq1";
  };

  version = "0.0.1";

  dependencies = pkgs.buildEnv {
    name = "nix-format-dependencies-${version}";
    paths = with pkgs; [
      coreutils
      emacs
      diffutils
      meld
    ];
  };

  nixFormatElisp = pkgs.runCommand "nix-format-elisp-${version}" {} ''
    substitute ${./nix-format.el} "$out" \
        --subst-var-by NIX_MODE_PATH "${nixMode}"
  '';

  nixFormat = pkgs.runCommand "nix-format-${version}" {} ''
    mkdir -p "$out/bin"
    substitute ${./wrapper.sh} "$out/bin/nix-format"         \
        --subst-var-by DEPENDENCIES      "${dependencies}"   \
        --subst-var-by VERSION           "${version}"        \
        --subst-var-by NIX_FORMAT_SCRIPT "${nixFormatElisp}"
    chmod +x "$out/bin/nix-format"
  '';
}
