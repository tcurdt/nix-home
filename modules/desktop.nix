# Desktop/laptop base with Hyprland. Use instead of server.nix, not together.
#
# Login is via greetd/tuigreet, which starts Hyprland through uwsm (systemd
# session management). On first start Hyprland writes a default
# ~/.config/hypr/hyprland.conf that uses kitty and wofi, both included here.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = lib.mkDefault "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;

  boot.tmp.cleanOnBoot = true;
  # compressed RAM swap, used before any swap on disk
  zramSwap.enable = true;

  # maintenance

  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
    persistent = true; # catch up if the machine was off
  };
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

  # networking

  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ ];
  networking.firewall.allowedUDPPorts = [ ];
  services.resolved.enable = true;
  services.chrony.enable = true;

  # strict reverse path filtering: reject packets whose source isn't
  # reachable through the receiving interface (spoof protection)
  boot.kernel.sysctl = {
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
  };

  # login

  services.greetd = {
    enable = true;
    settings.default_session = {
      user = "greeter";
      command = lib.concatStringsSep " " [
        (lib.getExe pkgs.tuigreet)
        "--time"
        "--remember"
        "--asterisks"
        "--cmd '${lib.getExe config.programs.uwsm.package} start hyprland-uwsm.desktop'"
      ];
    };
  };

  # hyprland

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  programs.hyprlock.enable = true;
  services.hypridle.enable = true;
  programs.waybar.enable = true;

  # file picker etc. for apps that don't talk to the hyprland portal
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # electron/chromium apps run natively on wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  security.polkit.enable = true;

  # hardware

  hardware.graphics.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  services.blueman.enable = true;

  services.libinput.enable = true;

  # power

  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = lib.mkDefault true;
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "suspend";
  };

  services.fstrim.enable = true;
  services.fwupd.enable = true;

  # storage: automount usb drives, trash, mtp

  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # printing
  # services.printing.enable = true;
  # services.avahi = {
  #   enable = true;
  #   nssmdns4 = true;
  # };

  # fonts

  fonts.packages = [
    pkgs.noto-fonts
    pkgs.noto-fonts-color-emoji
    pkgs.nerd-fonts.jetbrains-mono
  ];

  # apps

  programs.firefox.enable = true;

  environment.systemPackages = [
    # defaults of the generated hyprland.conf
    pkgs.kitty
    pkgs.wofi

    # session
    pkgs.hyprpolkitagent
    pkgs.hyprpaper
    pkgs.mako
    pkgs.networkmanagerapplet

    # screenshots and clipboard
    pkgs.grim
    pkgs.slurp
    pkgs.hyprshot
    pkgs.wl-clipboard

    # hardware keys and audio
    pkgs.brightnessctl
    pkgs.playerctl
    pkgs.pavucontrol

    # cli
    pkgs.nano
    pkgs.curl
    pkgs.gitMinimal
    pkgs.openssl
    pkgs.nvd
  ];

  services.openssh = {
    enable = true;
    allowSFTP = true;
    settings = {
      # AllowUsers = [];
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    extraConfig = ''
      IgnoreRhosts yes
      AllowTcpForwarding yes
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AuthenticationMethods publickey
    '';
  };

}
