{
  config,
  lib,
  ...
}:
{

  networking.hostName = "macbook-air";
  networking.domain = "home";
  system.stateVersion = "26.05";

  security.pki.certificateFiles = [ ../ca/home.crt ];

  imports = [

    ../hardware/macbook-air.nix

    ../modules/desktop.nix

    ../modules/users.nix
    ../users/root.nix
    ../users/tcurdt.nix
    {
      # users.users.root.password = "secret";
      users.users.root.hashedPasswordFile = "/secrets/users/root.hash";
      users.users.tcurdt.hashedPasswordFile = "/secrets/users/tcurdt.hash";
    }
    {
      # single-user laptop: the disk passphrase at boot is the login.
      # Runs once per boot; logging out shows the normal login screen.
      services.greetd.settings.initial_session = {
        user = "tcurdt";
        command = "${lib.getExe config.programs.uwsm.package} start hyprland-uwsm.desktop";
      };
    }
    {
      # desktop config files, linked into ~/.config. The "${...}" copies each
      # file into the store with the system; a bare path would only be a
      # string and the link would point nowhere on the machine.
      users.users.tcurdt.profile.files = {
        ".config/hypr/hyprland.lua" = "${../desktop/hypr/hyprland.lua}";
        ".config/hypr/hypridle.conf" = "${../desktop/hypr/hypridle.conf}";
        ".config/hypr/hyprlock.conf" = "${../desktop/hypr/hyprlock.conf}";
        ".config/mako/config" = "${../desktop/mako/config}";
        ".config/fuzzel/fuzzel.ini" = "${../desktop/fuzzel/fuzzel.ini}";
        ".config/waybar/config.jsonc" = "${../desktop/waybar/config.jsonc}";
        ".config/waybar/style.css" = "${../desktop/waybar/style.css}";
      };
    }
  ];

}
