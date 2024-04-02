with (import (fetchTarball {
  name = "nixpkgs-22.11";
  url = "https://github.com/nixos/nixpkgs/archive/22.11.tar.gz";
  # obtained by running nix-prefetch-url --name <name> --unpack <url>
  sha256 = "11w3wn2yjhaa5pv20gbfbirvjq6i3m7pqrq2msf0g7cv44vijwgw";
}) {});

let
  requiredNixVersion = "2.3";
  pwd = builtins.getEnv "PWD";
in

/* if stdenv.lib.versionOlder builtins.nixVersion requiredNixVersion == true then */
/*   abort "This project requires Nix >= ${requiredNixVersion}, please run 'nix-channel --update && nix-env -i nix'." */
/* else */
assert lib.asserts.assertMsg (lib.versionOlder builtins.nixVersion requiredNixVersion == false) ''
  This project requires Nix >= ${requiredNixVersion}, but ${builtins.nixVersion} is installed.
  Please run 'nix-channel --update && nix-env -i nix'.
'';

  mkShell {
    buildInputs = [
      stdenv
      git
      awscli
      cacert
      unixODBC

      # Ruby dependencies
      ruby_3_1
      bundler

    ] ++ lib.optional (!stdenv.isDarwin) [
      # linux-only packages
      glibcLocales
    ];

    BUNDLE_BUILD__RUBY___ODBC = "--with-odbc-dir=${pkgs.unixODBC}";
    BUNDLE_PATH = "vendor/bundle";
    NIX_PROJECT = builtins.baseNameOf pwd;
  }
