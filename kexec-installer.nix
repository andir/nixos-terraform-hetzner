
{
  extraConfig ? {...}: {},
}:
let
  pkgs = import <nixpkgs> {};
  config = (import <nixpkgs/nixos> {
    configuration = {
      imports = [
        <nixpkgs/nixos/modules/installer/netboot/netboot-minimal.nix>
        extraConfig
      ];
    };
  }).config;
  inherit (config.system) build;
  kexecScript = pkgs.writeScript "kexec-installer" ''
    #!/bin/sh
    if ! kexec -v >/dev/null 2>&1; then
      echo "kexec not found: please install kexec-tools" 2>&1
      exit 1
    fi
    kexec --load ./bzImage \
      --initrd=./initrd.gz \
      --command-line "init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}"

    echo "kexec in 5 sec..."
    sleep 5
    kexec -e
  '';
in pkgs.linkFarm "netboot" [
  { name = "initrd.gz"; path = "${build.netbootRamdisk}/initrd"; }
  { name = "bzImage";   path = "${build.kernel}/bzImage"; }
  { name = "kexec-installer"; path = kexecScript; }
]

