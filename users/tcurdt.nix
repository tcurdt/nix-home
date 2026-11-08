{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  users.users.tcurdt = {
    profile = import inputs.user.profile.tcurdt;
    shell = pkgs.bash;

    openssh.authorizedKeys.keyFiles = [ ../keys/tcurdt.pub ];

    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
    ];

    hashedPassword = lib.mkIf (config.users.users.tcurdt.hashedPasswordFile == null) "*";
  };
}
