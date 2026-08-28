{
  # pkgs,
  ...
}:
{

  networking.hostName = "home-ber";
  networking.domain = "home";
  system.stateVersion = "23.11";

  security.pki.certificateFiles = [ ../ca/home.crt ];

  imports = [

    ../hardware/lenovo.nix

    ../modules/server.nix
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

    { users.users.root.password = "secret"; }

    ../modules/webserver.nix
    ../modules/oidc.nix
    ../modules/forgejo.nix
    ../modules/grafana.nix
  ];

  services.my.webserver = {
    enable = true;
    # acme = "email@example.com";
  };

  # openssl rand -hex 32 | tr -d "\n" > /secrets/pocket-id/secret.key
  # open https://id.home/setup
  services.my.oidc = {
    server = "id.home";
    domain_crt = "/secrets/certs/id.home/server.crt";
    domain_key = "/secrets/certs/id.home/server.key";

    # groups = [
    #   {
    #     name = "forgejo_admins";
    #   }
    #   {
    #     name = "grafana_admins";
    #   }
    # ];

    # clients = [
    #   {
    #     client_id = "forgejo";
    #     pkce = true;
    #     consent = false;
    #     callbacks = [
    #       "https://git.home/user/oauth2/pocket-id/callback"
    #     ];
    #     secret = "/secrets/forgejo/oidc-client-secret";
    #   }
    #   {
    #     client_id = "grafana";
    #     pkce = true;
    #     consent = false;
    #     callbacks = [
    #       "https://grafana.home/login/generic_oauth"
    #     ];
    #     secret = "/secrets/grafana/oidc-client-secret";
    #   }
    # ];
  };

  services.my.forgejo = {
    server = "git.home";
    domain_crt = "/secrets/certs/git.home/server.crt";
    domain_key = "/secrets/certs/git.home/server.key";
    oidc = {
      issuer = "id.home";
      adminGroup = "forgejo_admins";
    };
  };

  services.my.grafana = {
    server = "grafana.home";
    domain_crt = "/secrets/certs/grafana.home/server.crt";
    domain_key = "/secrets/certs/grafana.home/server.key";
    oidc = {
      issuer = "id.home";
      adminGroup = "grafana_admins";
    };
    # dashboards = [
    # ];
    # datasources = [
    # ];
  };

}
