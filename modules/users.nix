{
  # pkgs,
  ...
}:
{
  security.sudo.wheelNeedsPassword = false;
  security.sudo.execWheelOnly = true;

  users.mutableUsers = false;

  # home-manager = {
  #   useGlobalPkgs = true;
  #   useUserPkgs = true;
  # };

  # nix.settings = {
  #   trusted-users = [ "@wheel" ];
  #   allowed-users = [ "@wheel" ];
  # };
  # nix.allowedUsers = [ "@wheel" ];

}
