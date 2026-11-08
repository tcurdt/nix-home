# Desktop/laptop base with Hyprland. Use instead of server.nix, not together.
#
# Login is via greetd/tuigreet, which starts Hyprland through uwsm (systemd
# session management). The per-user config files (Hyprland, bar, launcher,
# notifications, idle/lock) live in ../desktop and are linked by the machine.
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

  # quiet boot: kernel messages stay on tty1, the login screen runs on tty2
  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    "quiet"
    "console=tty1"
    "udev.log_level=3"
    "systemd.show_status=auto"
  ];
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

  # login

  services.greetd = {
    enable = true;
    # keeps boot and error output from drawing over the greeter
    useTextGreeter = true;
    settings.terminal.vt = lib.mkForce 2;
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

  systemd.services.greetd.serviceConfig.TTYPath = lib.mkForce "/dev/tty2";

  # hyprland

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  programs.hyprlock.enable = true;
  services.hypridle.enable = true;
  programs.waybar.enable = true;

  # user services get a minimal PATH by default; the bar launches powermenu
  # and pavucontrol, the idle daemon dims via brightnessctl
  systemd.user.services.waybar.enableDefaultPath = false;
  systemd.user.services.hypridle.path = [ pkgs.brightnessctl ];

  # file picker etc. for apps that don't talk to the hyprland portal
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # electron/chromium apps run natively on wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # password prompts for apps that need root (mounting disks etc.)
  security.polkit.enable = true;
  systemd.packages = [ pkgs.hyprpolkitagent ];
  systemd.user.services.hyprpolkitagent.wantedBy = [ "graphical-session.target" ];

  # nm-applet: no "connection established" popups
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/nm-applet" = {
        disable-connected-notifications = true;
        disable-disconnected-notifications = true;
      };
    }
  ];

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
    pkgs.kitty
    pkgs.fuzzel # launcher

    # power menu (CMD+SHIFT+Q and the bar's power button)
    (pkgs.writeShellApplication {
      name = "powermenu";
      runtimeInputs = [ pkgs.fuzzel ];
      text = ''
        choice=$(printf '%s\n' "Lock" "Log out" "Suspend" "Restart" "Shut down" |
          fuzzel --dmenu --prompt "" --lines 5 --width 14) || exit 0
        case "$choice" in
          "Lock") loginctl lock-session ;;
          "Log out") uwsm stop ;;
          "Suspend") systemctl suspend ;;
          "Restart") systemctl reboot ;;
          "Shut down") systemctl poweroff ;;
        esac
      '';
    })

    # session
    pkgs.hyprpolkitagent
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
