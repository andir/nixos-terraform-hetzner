let
  disk = "/dev/sda";
  defaultPartitioningScript = { pkgs }: ''
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | ${pkgs.utillinux}/bin/fdisk ${disk}
      o # clear the in memory partition table
      n # new partition
      p # primary partition
      1 # partition number 1
        # default - start at beginning of disk
        # default, extend partition to end of disk
      a # make a partition bootable
      1 # bootable partition is partition 1 -- /dev/sda1
      p # print the in-memory partition table
      w # write the partition table
      q # and we're done
    EOF
  '';
  defaultFormatScript = { pkgs }: ''
    ${pkgs.e2fsprogs}/bin/mkfs.ext4 ${disk}1
  '';
  defaultMountScript = { pkgs }: ''
    mkdir -p /mnt
    ${pkgs.utillinux}/bin/mount -t ext4 ${disk}1 /mnt
  '';
in
{
  extraConfig ? {...}: {},
}:
let
  pkgs = import <nixpkgs> {};
  config = (import <nixpkgs/nixos> {
    configuration = {
      imports = [
        <nixpkgs/nixos/modules/installer/netboot/netboot-minimal.nix>
        ./installer.nix
        ({pkgs, lib, ...}: {
          installer.partition = lib.mkDefault (pkgs.callPackage defaultPartitioningScript {});
          installer.format = lib.mkDefault (pkgs.callPackage defaultFormatScript {});
          installer.mount = lib.mkDefault (pkgs.callPackage defaultMountScript {});
          installer.configFiles = [
            (pkgs.writeText "grub.nix" ''
            {
              boot.loader.grub.devices = [ "${disk}" ];
            }
            '')
          ];
        })
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

