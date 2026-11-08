{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  users.users.root = {
    profile = import inputs.user.profile.tcurdt;
    shell = pkgs.bash;

    openssh.authorizedKeys.keyFiles = [ ../keys/tcurdt.pub ];

    # hashedPassword = lib.mkIf (config.users.users.root.hashedPasswordFile == null) "*";
  };
}
