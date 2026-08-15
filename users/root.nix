{
  # config,
  pkgs,
  inputs,
  ...
}:
{

  imports = [ inputs.home-manager.nixosModules.default ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  users.users.root = {
    shell = pkgs.bash;
    openssh.authorizedKeys.keyFiles = [ ../keys/tcurdt.pub ];

    # password = "secret";
    # promptInitialPassword = true;
    # hashedPassword = "*"; # no password allowed

  };

  home-manager.users.root = (import ../home/tcurdt.nix pkgs) // { };
}
