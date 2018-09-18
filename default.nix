let
  kexec-installer = import ./kexec-installer.nix;
in {
  installer = kexec-installer {
    extraConfig = { pkgs, ... }: {
      users.extraUsers.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqpqC3YXnoh+2fgOWbjCoOSnBv93+K9rpYSg0DuNIq7 andi@ranzbook"
      ];
      environment.systemPackages = with pkgs; [ vim tmux ];
      services.openssh = {
         enable = true;
         startWhenNeeded = true;
      };
    };
  };
}
