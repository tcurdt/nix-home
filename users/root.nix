{
  pkgs,
  ...
}:
{
  users.users.root = {
    profile = import ../profiles/tcurdt.nix;
    shell = pkgs.bash;

    openssh.authorizedKeys.keyFiles = [ ../keys/tcurdt.pub ];

    # hashedPassword = "*"; # no password allowed
    # password = "secret";
    # promptInitialPassword = true;
  };
}
