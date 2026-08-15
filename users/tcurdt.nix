{
  pkgs,
  ...
}:
{
  users.users.tcurdt = {
    profile = import ../profiles/tcurdt.nix;
    shell = pkgs.bash;

    openssh.authorizedKeys.keyFiles = [ ../keys/tcurdt.pub ];

    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    hashedPassword = "*"; # no password allowed
  };
}
