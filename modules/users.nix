{ inputs, ... }:
{
  imports = [ inputs.user.nixosModules.profiles ];

  security.sudo.wheelNeedsPassword = false;
  security.sudo.execWheelOnly = true;

  users.mutableUsers = false;
}
