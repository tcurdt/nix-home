{
  inputs,
  pkgs,
  ...
}:
{
  users.users.root = {
    profile = import inputs.user.profile.tcurdt;
    shell = pkgs.bash;

    openssh.authorizedKeys.keyFiles = [ ../keys/tcurdt.pub ];

    # hashedPassword = "*"; # no password allowed
    # password = "secret";
    # promptInitialPassword = true;
  };
}
