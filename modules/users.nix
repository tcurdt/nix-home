{ inputs, ... }:
{
  imports = [ inputs.user.nixosModules.profiles ];

  security.sudo.wheelNeedsPassword = false;
  security.sudo.execWheelOnly = true;

  users.mutableUsers = false;

  # nix.settings = {
  #   trusted-users = [ "@wheel" ];
  #   allowed-users = [ "@wheel" ];
  # };
  # nix.allowedUsers = [ "@wheel" ];

}
