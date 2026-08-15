{ ... }:
{
  imports = [ ./profiles.nix ];

  security.sudo.wheelNeedsPassword = false;
  security.sudo.execWheelOnly = true;

  users.mutableUsers = false;

  # nix.settings = {
  #   trusted-users = [ "@wheel" ];
  #   allowed-users = [ "@wheel" ];
  # };
  # nix.allowedUsers = [ "@wheel" ];

}
