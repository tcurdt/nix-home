{
  # pkgs,
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
    {
      # strict filtering rejects packets unless their source is reachable through
      # the receiving interface, providing spoof protection for conventional routing.
      boot.kernel.sysctl = {
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.conf.all.rp_filter" = 1;
      };
    }

    ../modules/users.nix
    ../users/root.nix
    ../users/tcurdt.nix
    {
      users.users.root.password = "secret";
      # users.users.root.hashedPasswordFile = "/secrets/users/root.hash";
      users.users.tcurdt.hashedPasswordFile = "/secrets/users/tcurdt.hash";
    }
  ];

}
