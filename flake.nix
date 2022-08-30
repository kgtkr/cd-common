{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      with pkgs; rec {
        packages = { };
        apps = {
          format = {
            type = "app";
            program = (writeShellScript "format" ''
              nixpkgs-fmt $(git ls-files ':(attr:!linguist-generated)*.nix')
              prettier $(git ls-files ':(attr:!linguist-generated)*.yaml') --write
            '').outPath;
          };
          fetch-cert = {
            type = "app";
            program = (writeShellScript "fetch-cert" ''
              kubeseal --fetch-cert > cert.pem
            '').outPath;
          };
          backup-certs = {
            type = "app";
            program = (writeShellScript "backup-certs" ''
              kubectl get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml
            '').outPath;
          };
          create-secret = {
            type = "app";
            program = (writeShellScript "create-secret" ''
              tr -d '\n' | kubeseal --raw --from-file=/dev/stdin --scope namespace-wide --namespace $1
            '').outPath;
          };
          create-wide-secret = {
            type = "app";
            program = (writeShellScript "create-wide-secret" ''
              tr -d '\n' | kubeseal --raw --from-file=/dev/stdin --scope cluster-wide
            '').outPath;
          };
        };
        devShell = mkShell {
          packages = [
            argocd
            kubeseal
            nixpkgs-fmt
            nodePackages.prettier
          ];
        };
      }
    );
}
