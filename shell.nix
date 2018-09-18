{ pkgs ? import <nixpkgs> {}}:
let
  terraform = pkgs.terraform.withPlugins (p: [ p.hcloud p.null]);
in pkgs.mkShell {
  buildInputs = [ terraform ];
}
