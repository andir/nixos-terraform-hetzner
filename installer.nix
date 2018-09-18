{pkgs, lib, config, ...}:
let
  cfg = config.installer;
in
with lib;
{
  options.installer = {
    partition = mkOption {
      description = "partitioning commands";
      type = types.string;
    };
    format = mkOption {
      description = "format commands";
      type = types.string;
    };
    mount = mkOption {
      description = "mount commands";
      type = types.string;
    };
    mountPoint = mkOption {
      description = "location the new rootfs will be mounted at";
      type = types.string;
      default = "/mnt";
    };
    configFiles = mkOption {
      description = ''
        list of config modules that should be deployed to the target system.
        All files will be included from the file /etc/nixos/terraform.nix.
      '';
      type = types.listOf types.path;
    };
  };
  config = {
      systemd.services.doinstall = {
        wantedBy = [ "multi-user.target" ];
        after = [ "multi-user-target" ];
        environment = {
          NIX_PATH = "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/root/channels";
          HOME = "/root";
        };
        script = ''
          PATH=/run/current-system/sw/bin/:$PATH
          udevadm settle
          ${cfg.partition}
          udevadm settle
          ${cfg.format}
          udevadm settle
          ${cfg.mount}

          nixos-generate-config --root ${cfg.mountPoint}
          mkdir -p ${cfg.mountPoint}/etc/nixos/terraform/

          cp \
          ${concatMapStrings
            (x: "  ${x} \\\n")
            cfg.configFiles
          } ${cfg.mountPoint}/etc/nixos/terraform/

          pushd ${cfg.mountPoint}/etc/nixos
          (
            echo "{ imports = [";
            find ./terraform/ -type f;
            echo "]; }"
          ) > terraform.nix
          popd

          sed -i 's;./hardware-configuration.nix;./hardware-configuration.nix ./terraform.nix;g' ${cfg.mountPoint}/etc/nixos/configuration.nix

          nixos-install --root ${cfg.mountPoint} < /dev/null

          reboot
        '';
      };
  };
}
