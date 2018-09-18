let
  kexec-installer = import ./kexec-installer.nix;
in {
  installer = kexec-installer {
    extraConfig = {
      imports = [
        ./config.nix
      ];
      installer.configFiles = [ ./config.nix ];
    };
  };
}
