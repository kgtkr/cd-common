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
        devShell = mkShell {
          packages = [
            argocd
            kubeseal
            nixpkgs-fmt
            nodePackages.prettier
            (writeShellScriptBin "cd-format" ''
              nixpkgs-fmt $(git ls-files ':(attr:!linguist-generated)*.nix')
              prettier $(git ls-files ':(attr:!linguist-generated)*.yaml') --write
            '')
            (writeShellScriptBin "cd-fetch-cert" ''
              kubeseal --fetch-cert > cert.pem
            '')
            (writeShellScriptBin "cd-backup-certs" ''
              kubectl get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml
            '')
            (writeShellScriptBin "cd-create-secret" ''
              tr -d '\n' | kubeseal --raw --from-file=/dev/stdin --scope namespace-wide --namespace $1
            '')
            (writeShellScriptBin "cd-create-wide-secret" ''
              tr -d '\n' | kubeseal --raw --from-file=/dev/stdin --scope cluster-wide
            '')
          ];
          SEALED_SECRETS_CONTROLLER_NAMESPACE = "sealed-secrets";
          SEALED_SECRETS_CONTROLLER_NAME = "sealed-secrets";
          SEALED_SECRETS_CERT = ./cert.pem;
        };
      }
    );
}
